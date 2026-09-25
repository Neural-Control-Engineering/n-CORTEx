function [STAT, idxSel, drop, aligned] = nexOp_compileSTAT(nexObj, dfID, S_categories, S_items, idxSel, precompiled)
    % for each DF in DF_col, use dim selection (bus) to slice coordinate of
    % interest and arrange a multi-factoral column-wise grouping/labeling
    % for downstream analysis/visualization
    % extract grouping columns (for every selection that is not empty)
    % for each category (use items)
    %
    % precompiled (optional, mdlObj callers only): struct(TF, idxSel, drop)
    % as returned via the 4th output `aligned` from an earlier call. When
    % supplied, skips straight past raw-compile + CO-AXIS ALIGNMENT below —
    % including the fitSentinel/refreshPointerFromPool side effects —
    % reusing that earlier alignment's TF/idxSel/drop verbatim. This is
    % what mdlObject.precompileSTAT()/compileSTAT() use to let a Pointer
    % subselection made AFTER canonicalizing survive into pooling instead
    % of being wiped by a second refreshPointerFromPool call (see
    % mdlObject.invalidatePrecompile() for when this cache gets cleared).

    if nargin < 6, precompiled = []; end
    nexon = nexObj.nexon;

    if ~isempty(precompiled)
        TF     = precompiled.TF;
        idxSel = precompiled.idxSel;
        drop   = precompiled.drop;
    else
    % READ DATA / RESPONSE VARIABLE
    if isempty(idxSel)
            % GLOBAL FILTER
            S = nex_returnSelectionMask(nexon.console.BASE.controlPanel.averagingSelection);
            idxSel = nex_applySelectionMask(nexon.console.BASE.DTS,S);
            % TF = dtsIO_readTF(nexon, dfID, idxSel);
            try
                S_items = nex_returnSelectionMask(nexObj.Origin.selectionBus.items);
            catch
                keyboard
            end
            S_categories = nex_returnSelectionMask(nexObj.Origin.selectionBus.categories);
            S_merge = nexOp_mergeSelections_categorical(S_categories, S_items);
            idxSel = [idxSel & nex_applySelectionMask(nexon.console.BASE.DTS, S_merge)];
    end
    % Build ptr from ax-- category selections for hyperslab reads.
    ptr_filter = nexOp_buildPtrFromAxSel(S_categories, S_items, nexObj);
    [TF, drop] = nexOp_compileTF(nexObj.nexon, idxSel, dfID, ptr_filter);

    % CO-AXIS ALIGNMENT — canonicalize FTR axis across sessions, on the RAW
    % TF, before any pooling. Must happen first: positional (axID) pooling
    % computes bin edges from each trial's own raw axis extent, which is
    % session-relative — canonicalizing afterward would align already-
    % scrambled, session-relative bin labels rather than true cross-session
    % identity. NaN-fill in alignCoAxes plus 'omitnan' in pm.pool() (called
    % below) means padded positions never bias the subsequent pooling mean.
    try
        % nexObj is an mdlObj handle-class instance, not a struct —
        % isfield() always returns false for non-struct types even when the
        % property genuinely exists. Use fieldnames-membership instead,
        % which works for both structs and objects.
        hasRegField = ismember('domain', fieldnames(nexObj)) && isfield(nexObj.domain, 'REG');
        if hasRegField && ~isempty(nexObj.domain.REG) && ~strcmp(char(nexObj.domain.REG), 'None')
            [TF, canonReg, ftrAxis] = nexOp_alignCoAxes(TF, char(nexObj.domain.REG));
            % Cache the canonical set this compileSTAT call established, so
            % scaleApply_transform can later project each new raw per-trial
            % DF onto these SAME canonical positions at inference time
            % (CoRegistration_Design.md, "Inference-Time Projection"). Only
            % mdlObj instances carry this property — nexObject subclasses
            % (which also route through nexOp_compileSTAT) don't, hence the
            % fieldnames guard rather than a direct property check.
            if ismember('fitSentinel', fieldnames(nexObj))
                nexObj.fitSentinel = struct('regAxis', char(nexObj.domain.REG), ...
                                             'canonReg', canonReg, 'ftrAxis', ftrAxis);
            end
        end
    catch e
        fprintf('[nexOp_compileSTAT] alignCoAxes skipped: %s\n', e.message);
    end

    % Seed/refresh the Pointer bus from THIS alignment's own axis layout
    % (canonicalized if REG was set, else just TF's current — un-cached —
    % layout), pooled through mdlObj's CURRENT pMap: cheap, label-only (see
    % refreshPointerFromPool — never touches .df), so "select all" in the
    % UI actually means all of what Fit/CV will really see. Runs once per
    % fresh alignment (Compile press, or a cold Fit that skipped Compile)
    % — this whole branch is skipped on a cache-reusing compileSTAT() call
    % (see the `if ~isempty(precompiled)` above), so a Pointer/pMap
    % subselection made after this survives into repeated Fits untouched.
    if ismethod(nexObj, 'refreshPointerFromPool') && ~isempty(TF)
        try
            nexObj.refreshPointerFromPool(TF{1});
        catch e
            fprintf('[nexOp_compileSTAT] refreshPointerFromPool skipped: %s\n', e.message);
        end
    end
    end
    aligned = struct('TF', {TF}, 'idxSel', idxSel, 'drop', drop);

    % AXIS POOLING
    try
        try
            ptr = nexObj.DF_postOp.ptr;
        catch
            ptr = nexObj.Origin.DF_postOp.ptr;
        end
        pm = nexObj.pMap;
        % When any pMap axis is reduce-mode (divsPerBin < 0), skip ALL
        % pooling/relabeling here entirely — not just that axis's own
        % no-op — and defer everything to fitReduce/applyReduce (raw-time
        % block-PCA) + nexOp_poolStackedDM (pooling AFTER reduction, on the
        % reduced output). Pooling any OTHER axis here first would still
        % decimate the samples reduction needs to see at full resolution
        % (see WIP.md #3) — the reduce-mode axis's own no-op alone isn't
        % enough once a pool-mode axis coexists with it.
        needsHR = false;
        if ~isempty(pm)
            pmFields = fieldnames(pm);
            needsHR  = any(arrayfun(@(i) pm.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
        end
        if needsHR
            TF_pooled = TF;
        elseif ~isempty(pm)
            try
                TF_pooled = cellfun(@(DF) nexOp_poolAxes(pm, DF, ptr), TF, "UniformOutput",false);
            catch
                keyboard
            end
        else
            TF_pooled = TF;
        end
    catch
        TF_pooled = TF;
    end

    % READ CATEGORY LABELS / FIXED+RANDOM VARIABLES
    categories = fieldnames(S_categories);
    categories_ax = [];
    % sessionLabel and var
    Y = []; % container for category items (across all selected samples)
    categoryProps = []; % list of applicable categories
    selMatch = ones(size(idxSel(idxSel==1)));
    selMatch= selMatch(~drop);
    for i = 1:length(categories)
        category = categories{i};
        categoryID = char(string(S_categories.(category)));   % normalise: string/char/cell → char
        if ~isempty(categoryID) && ~contains(categoryID, "ax") && ~strcmp(categoryID, "None")
            TF_category = dtsIO_readTF_category(nexon, categoryID, idxSel);
            TF_category = TF_category(~drop); % filter empty entries
            Y = [Y, TF_category];
            categoryProps = [categoryProps; string(strrep(categoryID,"--","_"))];
            selMatch = [selMatch & ismember(TF_category, S_items.(category))];
        end
    end
    if isempty(Y)
        % No category constraints — use sessionLabel as the default grouping so
        % the downstream findgroups / sort path works without special-casing.
        sessionLabels = string(nexon.console.BASE.DTS.sessionLabel(idxSel));
        sessionLabels = sessionLabels(~drop);
        Y = table(sessionLabels, 'VariableNames', {'sessionLabel_subj'});
        selMatch = true(height(Y), 1);
    else
        Y = array2table(Y, 'VariableNames', cellstr(categoryProps));
    end
    Y = Y(selMatch,:); % filter by intersection of all category selections
    TF_pooled = TF_pooled(selMatch); % filter selected data as well
    % enumerate rows as trial numbers, relative to subject/phase combos
    % TF_trialNum = nexon.console.BASE.DTS.trialNumber(idxSel);
    try
        [G, groups] = findgroups(Y.sessionLabel_subj, Y.sessionLabel_phase);    
    catch
        [G, groups] = findgroups(Y.sessionLabel_subj);    
    end
    % sort groups
    [G_sort, idx_sort] = sort(G);
    % TF_trialNum_sort = TF_trialNum(idx_sort);
    n = splitapply(@(x) {(1:numel(x))'}, G_sort, G_sort);    
    TF_trialNum = cat(1,n{:});
    % TF_trialNum = TF_trialNum(selMatch,:);        
    Y = Y(idx_sort,:); % sort Y by groups
    TF_pooled = TF_pooled(idx_sort,:); % sort TF by groups
    Y.trialNumber = TF_trialNum;
    
    % parallel parsing
    SS = outerjoinStructs(S_categories, S_items);
    keep = convertCharsToStrings(fieldnames(SS)); keep = keep(contains(keep, "ax"));
    SS_ax = rmfield(SS, setdiff(fieldnames(SS), keep));
    
    M = cell(size(TF_pooled));
    % tic
    for i = 1:height(Y)
        DF =TF_pooled{i};
        Y_i = Y(i,:);
        sample = nexStat_breakoutSample(DF, Y_i, SS_ax);
        M{i} = sample;
    end
    % toc
    % % ax
    % for i = 1:length(categories_ax)
    %     category = categories_ax(i);
    %     categoryID = S_categories.(category);
    %     categoryID = split(categoryID,"--"); categoryID = categoryID(2);
    %     % 
    % end
    STAT = cat(1, M{:});
    % STAT = [];
end

