function [STAT, idxSel, drop] = nexOp_compileSTAT(nexObj, dfID, S_categories, S_items, idxSel)
    % for each DF in DF_col, use dim selection (bus) to slice coordinate of
    % interest and arrange a multi-factoral column-wise grouping/labeling
    % for downstream analysis/visualization
    % extract grouping columns (for every selection that is not empty)
    % for each category (use items)

    nexon = nexObj.nexon;
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
                % The Pointer bus's option list for this axis may still be
                % built from a narrower, pre-canonicalization reference —
                % refresh it so "select all" actually means the full
                % canonical set (see refreshPointerFromSentinel).
                if ismethod(nexObj, 'refreshPointerFromSentinel')
                    nexObj.refreshPointerFromSentinel();
                end
            end
        end
    catch e
        fprintf('[nexOp_compileSTAT] alignCoAxes skipped: %s\n', e.message);
    end

    % AXIS POOLING
    try
        try
            ptr = nexObj.DF_postOp.ptr;
        catch
            ptr = nexObj.Origin.DF_postOp.ptr;
        end
        pm = nexObj.pMap;
        if ~isempty(pm)
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

