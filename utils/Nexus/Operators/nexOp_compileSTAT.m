function [STAT, idxSel, drop, aligned] = nexOp_compileSTAT(nexObj, dfID, S_categories, S_items, idxSel, precompiled, withinSubject)
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
    if nargin < 7 || isempty(withinSubject), withinSubject = true; end
    nexon = nexObj.nexon;

    % Which subjects went through the PER-SUBJECT alignment branch below
    % (set only there, fresh-compile path only) — drives the POST-POOLING
    % Pointer-seed union further down (Nexus WIP.md #10, point 4), which
    % runs unconditionally (regardless of precompiled), so this must be
    % initialized unconditionally too, not just on the fresh-compile path.
    uniqSubjAligned = string.empty;

    if ~isempty(precompiled)
        TF     = precompiled.TF;
        idxSel = precompiled.idxSel;
        drop   = precompiled.drop;
        % subjID is needed below regardless of whether alignment was
        % freshly run or reused from cache — per-DF pooling threading and
        % the subj_internal STAT column both run unconditionally further
        % down (Nexus WIP.md #10). The cache-reuse path skips straight
        % past the fresh-compile branch below (where this is otherwise
        % computed), so it must be computed here too, the same way.
        subjID = string.empty;
        try
            subjID = dtsIO_readTF_category(nexon, "sessionLabel--subj", idxSel);
            subjID = subjID(~drop);
        catch
            subjID = string.empty;
        end
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

    % Per-TF-row subject ID, aligned to TF's own row order — same read +
    % (~drop) filtering pattern the category loop below uses for every
    % other categoryID, just pulled forward so co-axis alignment (next)
    % can scope canonicalization to within-subject. Always computed (not
    % gated on withinSubject) — besides scoping REG canonicalization below,
    % it's now also needed for per-DF region-mode pooling (threaded into
    % nexOp_poolAxes further down) and for the subj_internal STAT column
    % (Nexus WIP.md #10), neither of which depends on withinSubject.
    subjID = string.empty;
    try
        subjID = dtsIO_readTF_category(nexon, "sessionLabel--subj", idxSel);
        subjID = subjID(~drop);
    catch
        subjID = string.empty;
    end

    % Per-TF-row human-readable trial identity (sessionLabel + trial
    % number), same alignment as subjID above — passed into
    % nexOp_alignCoAxes purely so its skip-diagnostic can name which real
    % trial is missing the REG axis, instead of an opaque TF-relative index.
    trialLabels = string.empty;
    try
        sessLbl = string(nexon.console.BASE.DTS.sessionLabel(idxSel));
        trialNum = nexon.console.BASE.DTS.trialNumber(idxSel);
        sessLbl  = sessLbl(~drop);
        trialNum = trialNum(~drop);
        trialLabels = sessLbl + "_trial" + string(trialNum);
    catch
        trialLabels = string.empty;
    end

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
            uniqSubj = string.empty;
            if withinSubject && ~isempty(subjID), uniqSubj = unique(subjID); end
            if numel(uniqSubj) > 1
                % Per-subject canonicalization — canonicalizing a REG
                % identity (e.g. 'chans') across DIFFERENT subjects'
                % probes/geometry is semantically wrong (subject A's
                % "chan 5" isn't subject B's "chan 5"). Run
                % nexOp_alignCoAxes once per subject's own TF subset and
                % scatter the results back into TF's original row order.
                TF_aligned = TF;
                canonRegBySubject = containers.Map('KeyType','char','ValueType','any');
                ftrAxis = "";
                for si = 1:numel(uniqSubj)
                    subjMask = (subjID == uniqSubj(si));
                    labels_s = string.empty;
                    if numel(trialLabels) == numel(subjMask), labels_s = trialLabels(subjMask); end
                    [TF_s, canonReg_s, ftrAxis_s] = nexOp_alignCoAxes(TF(subjMask), char(nexObj.domain.REG), [], [], labels_s);
                    TF_aligned(subjMask) = TF_s;
                    canonRegBySubject(char(uniqSubj(si))) = canonReg_s;
                    ftrAxis = ftrAxis_s;
                end
                TF = TF_aligned;
                % Remembered for the POST-POOLING Pointer-seed union further
                % down (Nexus WIP.md #10, point 4) — deliberately NOT built
                % here anymore. Building it from TF_aligned (as before)
                % would union raw channel numbers; the union now needs to
                % happen on TF_pooled, after region-mode pooling has run,
                % so Pointer reflects region NAMES instead.
                uniqSubjAligned = uniqSubj;
                % Cache per-subject canonical sets so scaleApply_transform
                % can later project each new raw per-trial DF onto the
                % SAME canonical positions its own subject was fit with
                % (CoRegistration_Design.md, "Inference-Time Projection").
                % Only mdlObj instances carry this property — nexObject
                % subclasses (which also route through nexOp_compileSTAT)
                % don't, hence the fieldnames guard rather than a direct
                % property check.
                if ismember('fitSentinel', fieldnames(nexObj))
                    nexObj.fitSentinel = struct('regAxis', char(nexObj.domain.REG), ...
                                                 'ftrAxis', ftrAxis, 'bySubject', true, ...
                                                 'canonReg', canonRegBySubject);
                end
            else
                [TF, canonReg, ftrAxis] = nexOp_alignCoAxes(TF, char(nexObj.domain.REG), [], [], trialLabels);
                if ismember('fitSentinel', fieldnames(nexObj))
                    nexObj.fitSentinel = struct('regAxis', char(nexObj.domain.REG), ...
                                                 'ftrAxis', ftrAxis, 'bySubject', false, ...
                                                 'canonReg', canonReg);
                end
            end
        end
    catch e
        fprintf('[nexOp_compileSTAT] alignCoAxes skipped: %s\n', e.message);
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
                % Indexed loop, not cellfun — each DF needs its OWN
                % subject threaded into nexOp_poolAxes so region-mode
                % (mapID) pooling resolves THAT subject's own registry
                % regMap instead of the single construction-time Map every
                % DF would otherwise share regardless of whose channels
                % they actually are (Nexus WIP.md #10). TF's row order here
                % still matches subjID's (nothing has reordered TF since
                % subjID was read above), so subjID(ti) <-> TF{ti} is a
                % direct positional match, no lookup needed.
                TF_pooled = cell(size(TF));
                for ti = 1:numel(TF)
                    s = string.empty;
                    if numel(subjID) == numel(TF), s = subjID(ti); end
                    TF_pooled{ti} = nexOp_poolAxes(pm, TF{ti}, ptr, s);
                end
            catch
                keyboard
            end
        else
            TF_pooled = TF;
        end
    catch
        TF_pooled = TF;
    end

    % Seed/refresh the Pointer bus — from TF_pooled (AFTER region-mode
    % pooling), not the pre-pooling TF, so a region-mode (mapID) axis shows
    % region NAMES, not raw channel numbers, and the cross-subject union
    % below (when per-subject alignment ran above) reflects region identity
    % rather than raw channel identity (Nexus WIP.md #10, point 4). Cheap,
    % label-only via refreshPointerFromPool — never touches real .df data,
    % so "select all" in the UI actually means all of what Fit/CV will
    % really see. Only on a FRESH alignment (precompiled was empty) — a
    % cache-reusing compileSTAT() call must not re-refresh and wipe a
    % Pointer/pMap subselection made since Compile was pressed.
    if isempty(precompiled) && ismethod(nexObj, 'refreshPointerFromPool') && ~isempty(TF_pooled)
        try
            pointerSeedDF  = TF_pooled{1};
            pointerSeedSubj = string.empty;
            if numel(uniqSubjAligned) > 1
                % Same two-tier pattern as the raw-channel alignment above,
                % one level up: one already-region-pooled representative
                % DF per subject, then union THOSE (by region name, since
                % nexOp_alignCoAxes coerces non-numeric REG values to
                % string) to get the Pointer bus's true cross-subject span.
                repPooled = {};
                for si = 1:numel(uniqSubjAligned)
                    repIdx = find(subjID == uniqSubjAligned(si), 1);
                    if ~isempty(repIdx), repPooled{end+1} = TF_pooled{repIdx}; end %#ok<AGROW>
                end
                if numel(repPooled) > 1
                    [TF_global, ~, ~] = nexOp_alignCoAxes(repPooled, char(nexObj.domain.REG));
                    pointerSeedDF = TF_global{1};
                end
                pointerSeedSubj = uniqSubjAligned;
            end
            nexObj.refreshPointerFromPool(pointerSeedDF, pointerSeedSubj);
        catch e
            fprintf('[nexOp_compileSTAT] refreshPointerFromPool skipped: %s\n', e.message);
        end
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
    % subj_internal companion — same selMatch filter, reordered alongside
    % Y/TF_pooled by idx_sort below, so it lands in final STAT row order.
    % Carried as a real STAT column (not a separately-tracked array) below
    % specifically so every later row-reordering/subsetting STAT undergoes
    % (fold masking, applyPointer, applyDomainMSR, ...) keeps it in
    % lockstep automatically — see Nexus WIP.md #10, point 2, and the
    % applyDomainMSR broadcast bug this session already found/fixed for
    % exactly the class of desync a hand-maintained parallel array risks.
    subjID_sel = string.empty;
    if numel(subjID) == numel(selMatch), subjID_sel = subjID(selMatch); end
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
    subjID_sorted = string.empty;
    if numel(subjID_sel) == numel(idx_sort), subjID_sorted = subjID_sel(idx_sort); end
    
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
    if numel(subjID_sorted) == height(STAT)
        STAT.subj_internal = subjID_sorted(:);
    end
    % Genuinely globally-unique per-row trial identifier -- STAT.trialNumber
    % (the literal DTS per-session count) resets to 1 at the start of EVERY
    % session, so it only disambiguates trials WITHIN one session, not
    % across them. A single subject with multiple sessions inside the same
    % CTG-combo/stratum (entirely normal) therefore has several real,
    % DIFFERENT trials all sharing trialNumber==1 -- confirmed directly:
    % find(STAT.sessionLabel_subj=="<subj>" & STAT.trialNumber==1) returned
    % 4 separate STAT rows for one real subject/stratum. Any caller that
    % needs "one real trial" (buildLongSTAT's per-trial quantization, a
    % tooFewGroups-style guard, ...) must key on THIS column instead --
    % trialUID is just STAT's own row index at compile time, which is
    % unique across the WHOLE compiled STAT regardless of how many
    % sessions/subjects it spans, and stays unique after any later row
    % subset (e.g. fitByCombo's child.STAT = mdlObj.STAT(mask,:)) since a
    % subset of distinct values is still distinct.
    STAT.trialUID = (1:height(STAT))';
    % STAT = [];
end

