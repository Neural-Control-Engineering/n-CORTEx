function nexAnalysis_cvPermute(mdlObj, resultID)
    if nargin < 2 || isempty(resultID)
        resultID = sprintf('cv_%s', char(datetime('now','Format','HHmmss')));
    end
% N-fold cross-validation with permutation null distribution.
%
%   nexAnalysis_cvPermute(mdlObj, resultID)
%
%   mdlObj : mdlObject subclass (linear, lda, logistic).
%            mdlObj.Parent must be the nexObj_categorical that drives
%            compileSTAT — wired at construction or by mdlObj_fromState.
%
% Folds are split at trial level to prevent data leakage across time.
% Permutations shuffle trial-level Y (preserving within-trial temporal
% structure) to build a null distribution per fold.
%
% Scores are time-resolved: scoreFold stacks all trial-time rows without
% averaging, predicts per (trial, time) pair, and returns balanced accuracy
% (or R²) at each time bin.
%
% CTG (domain.CTG) — category columns to stratify over.  One RESULT row per
% unique CTG combination; rows are navigated via the VW bus.
%
% SWP (domain.SWP) — one or more non-"None" Pointer axes (multi-select).
% Each selected axis is iterated as its own inner dimension of df (nested
% cross-product — e.g. region × time), rather than breaking into more rows.
% domain.DN(1)/FTR are never valid SWP candidates (dropped with a warning if
% picked) — that axis is what scoreFold already resolves per-timepoint, over
% its FULL un-swept extent. To sweep an axis instead of scoring it per-value,
% set domain.DN to something else (or "None") first.
%
% Result stored in mdlObj.RESULTS.(resultID) as a STAT-shaped table:
%   identity columns  — one per CTG variable (e.g. sessionLabel_subj)
%   df   {1×1}  [nFolds × (1+nPermute) × nTime]                  (no SWP axes)
%   df   {1×1}  [nFolds × (1+nPermute) × nTime × n1 × n2 × ...]  (SWP active,
%               one trailing dim per selected SWP axis, in selection order)
%   ax   {1×1}  struct with fold / perm / domain.DN(1) [/ one field per SWP axis]
%   ptr  {1×1}  axis pointer struct
%   fitSentinel {1×nSWP} cell of structs — one per SWP combo (nSWP = product
%               of all SWP axes' value counts, flattened column-major to
%               match df's trailing dims), or {1×1} when SWP is inactive.
%               Each struct holds the REG-canonical axis labels that
%               survived NaN-cropping for that iteration, i.e. which
%               canonical positions actually had data in this CTG-combo ×
%               SWP-combo slice, tightened down from the globally-aligned
%               canonical set computed in compileSTAT.

    cvCfg = mdlObj.cfg.cvCfg.entryParams;
    nFolds   = cvCfg.nFolds;
    nPermute = cvCfg.nPermute;

    % ── 1. Compile full STAT ─────────────────────────────────────────────────
    [STAT_full, idxSel, drop] = mdlObj.compileSTAT();
    tVar = char(mdlObj.dfID_target);
    if ~ismember(tVar, STAT_full.Properties.VariableNames)
        Y_tmp = dtsIO_readTF(mdlObj.nexon, tVar, idxSel, 'simple');
        Y_tmp = Y_tmp(~drop);
        STAT_full.(tVar) = Y_tmp;
    end

    fitArgs = mdlObj.cfg.fitCfg.entryParams;
    dmFcn   = str2func(sprintf('stat2dm_%s', mdlObj.cfg.dmCfg.format));

    % ── 2. CTG combo enumeration ─────────────────────────────────────────────
    ctgCols   = string(mdlObj.domain.CTG);
    validCTG  = ctgCols(ismember(ctgCols, string(STAT_full.Properties.VariableNames)));
    if ~isempty(validCTG)
        comboTbl = unique(STAT_full(:, cellstr(validCTG)), 'rows');
    else
        comboTbl = table();   % single "all data" combo
    end
    nCombos = max(1, height(comboTbl));

    % ── 3. DN(1) time axis (shared across combos) ─────────────────────────────
    % DN(1) == "None" means no training-domain axis at all — compileSTAT's
    % own convention is "trial is the sample" (it skips nexOp_permute2First
    % for exactly this reason). Score once per trial, not per-timepoint.
    dn = char(mdlObj.domain.DN(1));
    if strcmp(dn, "None")
        dnAx  = [];
        nTime = 1;
    else
        dnAx  = STAT_full.ax(1).(dn);
        nTime = numel(dnAx);
    end

    % ── 4. SWP outer-axis detection ──────────────────────────────────────────
    % SWP axes are extra dimensions inside df, NOT extra rows. domain.SWP is
    % a string array (multi-select bus) — multiple axes nest as a full
    % cross-product, one trailing df dimension per selected axis.
    %
    % The full designated training domain (domain.DN — not just DN(1)) is
    % never a valid SWP candidate, explicit selection or not: DN(1)
    % specifically is the axis scoreFold resolves per-timepoint scores over
    % (nTime, fixed above from the FULL un-swept axis) — sweeping it too
    % would slice every combo down to a single value while nTime upstream
    % still expects the full axis, starving folds down to far fewer samples
    % than the CTG/SWP combo count suggests. Nothing else in this file
    % structurally depends on DN(2+) staying full-width today, but treating
    % the whole designated domain as off-limits — not just the one index
    % this file happens to touch — is the simpler, less surprising rule.
    % The intended usage is either/or: set domain.DN to the axis/axes you
    % want fixed/scored, or set it to something else (or "None") and sweep
    % that axis via SWP instead.
    %
    % FTR has no such structural conflict — nFeat is computed dynamically
    % per fit call (e.g. size(mdlObj.DM.X,2) in nexFit_lda), nothing
    % precomputes or fixes a feature count ahead of this loop — so an
    % EXPLICIT domain.SWP selection of FTR (e.g. sweep each unit
    % individually as a per-unit screen) is honored. FTR is excluded only
    % from the UNGUIDED auto-detect fallback below, where silently sweeping
    % away the model's only feature axis without being asked would be a bad
    % guess, not from something deliberately selected.
    dnStr = string(mdlObj.domain.DN);

    swpIDs = string.empty(1, 0);
    if isfield(mdlObj.domain, 'SWP')
        domSWP = string(mdlObj.domain.SWP);
        swpIDs = domSWP(domSWP ~= "None");
    end
    skipped = swpIDs(ismember(swpIDs, dnStr));
    if ~isempty(skipped)
        warning(['[nexAnalysis_cvPermute] SWP axis "%s" is also the training axis ' ...
                 '(domain.DN) — dropping it from the sweep. To sweep this axis, ' ...
                 'remove it from domain.DN first (e.g. set DN to "None" or another axis).'], ...
                strjoin(skipped, '", "'));
        swpIDs = swpIDs(~ismember(swpIDs, dnStr));
    end
    if isempty(swpIDs)
        % Fall back to auto-detect: any ptr axis that is not DN or FTR and
        % has a real dim (the legacy behaviour before explicit SWP bus).
        ftrStr = string(mdlObj.domain.FTR);
        skip   = [dnStr, ftrStr];
        ptrAx  = string(fieldnames(STAT_full.ptr(1))');
        cands  = ptrAx(~ismember(ptrAx, skip));
        if ~isempty(cands)
            hasDim = arrayfun(@(ax) ~isempty(STAT_full.ptr(1).(char(ax)).dim), cands);
            cands  = cands(hasDim);
        end
        if ~isempty(cands), swpIDs = cands(1); end
    end

    % Resolve each candidate axis to its unique values + df dimension.
    % Iterate by unique label value, not raw positional index — axis
    % granularity (one-position-per-unit vs repeated-region-labels vs
    % fully-pooled-region) is entirely controlled upstream via poolMap's
    % groupBy/nDivsPerBin (see nexObj_poolMap/nexOp_poolAxes); SWP just
    % needs to group whatever labels it's handed. 'stable' keeps iteration
    % order matching physical axis order rather than sorting, since
    % repeated labels (e.g. region names) are typically contiguous along
    % the probe.
    swpAxes  = struct('id', {}, 'raw', {}, 'vals', {}, 'dim', {}, 'n', {});
    dimsUsed = [];
    for a = 1:numel(swpIDs)
        id  = swpIDs(a);
        raw = STAT_full.ax(1).(char(id));
        % id may be a co-indexed label with no dimension of its own
        % (e.g. 'chans' riding on 'unit') — resolve through the co-index
        % registry the same way nexOp_alignCoAxes resolves REG/FTR.
        dim = resolveAxisDim(STAT_full.ax(1), STAT_full.ptr(1), id);
        if isempty(dim)
            warning('[nexAnalysis_cvPermute] SWP axis "%s" has no resolvable dimension (not co-indexed to one either) — dropping it from the sweep.', id);
            continue;
        end
        if ismember(dim, dimsUsed)
            warning('[nexAnalysis_cvPermute] SWP axis "%s" shares its dimension with an earlier SWP axis — dropping it from the sweep.', id);
            continue;
        end
        dimsUsed(end+1) = dim; %#ok<AGROW>
        swpAxes(end+1) = struct('id', id, 'raw', raw, 'vals', unique(raw, 'stable'), ...
                                 'dim', dim, 'n', numel(unique(raw, 'stable'))); %#ok<AGROW>
    end
    hasSwp = ~isempty(swpAxes);
    if hasSwp
        nSwpPerAxis = [swpAxes.n];
        nSwp        = prod(nSwpPerAxis);
        fprintf('[nexAnalysis_cvPermute] SWP axes: %s (%s values -> %d combos)\n', ...
                strjoin([swpAxes.id], " x "), strjoin(string(nSwpPerAxis), " x "), nSwp);
    else
        nSwpPerAxis = [];
        nSwp        = 1;
    end

    % ── 4b. REG canonical dimension — for per-SWP-value NaN cropping ─────────
    % REG may itself be a co-indexed label (e.g. 'chans'); resolve the real
    % owning dimension the same way, so cropping operates on the axis that
    % actually carries the padded/pooled data.
    regAxis = "";
    if isfield(mdlObj.domain, 'REG') && mdlObj.domain.REG ~= "None"
        regAxis = mdlObj.domain.REG;
    end
    regDim = [];
    if regAxis ~= ""
        regDim = resolveAxisDim(STAT_full.ax(1), STAT_full.ptr(1), regAxis);
    end

    % ── 5. Main loop: CTG combos ─────────────────────────────────────────────
    resultRows = cell(nCombos, 1);

    for ci = 1:nCombos
        % ── 5a. Subset STAT for this CTG combo ───────────────────────────────
        if ~isempty(validCTG)
            mask = true(height(STAT_full), 1);
            for j = 1:numel(validCTG)
                col = char(validCTG(j));
                val = comboTbl.(col)(ci);
                if iscell(STAT_full.(col))
                    mask = mask & strcmp(STAT_full.(col), val);
                elseif isstring(STAT_full.(col))
                    mask = mask & (STAT_full.(col) == string(val));
                else
                    mask = mask & (STAT_full.(col) == val);
                end
            end
            STAT_ctg = STAT_full(mask, :);
            ctgLabel = strjoin(arrayfun(@(c) char(comboTbl.(char(c))(ci)), ...
                               validCTG, 'UniformOutput', false), ' | ');
        else
            STAT_ctg = STAT_full;
            ctgLabel  = 'all';
        end

        nTrials = height(STAT_ctg);
        if nTrials == 0
            fprintf('[nexAnalysis_cvPermute] combo %d/%d — no trials, skipping\n', ci, nCombos);
            continue;
        end
        fprintf('[nexAnalysis_cvPermute] combo %d/%d: %s  (%d trials)\n', ...
                ci, nCombos, ctgLabel, nTrials);

        % ── 5b. Y labels + fold allocation ───────────────────────────────────
        Y_ctg = STAT_ctg.(tVar);
        if iscell(Y_ctg), Y_flat = [Y_ctg{:}]'; else, Y_flat = Y_ctg(:); end
        isCont = isnumeric(Y_flat);
        if isCont
            cv         = cvpartition(nTrials, 'KFold', nFolds);
            trainMasks = arrayfun(@(k) {training(cv, k)}, 1:nFolds);
        else
            trainMasks = nexStat_allocateFolds(Y_flat, nFolds);
        end

        % ── 5c. SWP × fold × permute loop ────────────────────────────────────
        scores    = nan(nFolds, 1 + nPermute, nTime, nSwp);
        sentinels = cell(1, nSwp);

        for si = 1:nSwp
            if hasSwp
                % Decompose the flat combo index into one subscript per SWP
                % axis (column-major — axis 1 varies fastest, matching how
                % `scores` gets reshaped back to N-D in step 5e), then slice
                % STAT_ctg down each axis's own dimension in turn. Select
                % every position whose raw label matches that axis's chosen
                % unique value — a single index when labels are already
                % unique per-position (raw chans, or region+sub-bin), or
                % multiple indices when several positions share a label
                % (e.g. per-element region labels via groupBy='region',
                % nDivsPerBin=0). sliceDim/sliceSTAT need no changes for
                % this: MATLAB indexing already accepts a vector here.
                subs       = swpLinToSubs(si, nSwpPerAxis);
                STAT_si    = STAT_ctg;
                comboParts = strings(1, numel(swpAxes));
                for a = 1:numel(swpAxes)
                    val           = swpAxes(a).vals(subs(a));
                    swpIdx        = find(matchesSWPValue(swpAxes(a).raw, val));
                    STAT_si       = sliceSTAT(STAT_si, swpAxes(a).dim, swpIdx);
                    comboParts(a) = sprintf('%s=%s(%d feature(s))', swpAxes(a).id, string(val), numel(swpIdx));
                end
                fprintf('[nexAnalysis_cvPermute]   combo %d/%d: %s\n', si, nSwp, strjoin(comboParts, ', '));
            else
                STAT_si = STAT_ctg;
            end

            % Tighten to this iteration's own canonical support: drop REG
            % positions that are NaN (structurally absent) for every trial
            % in this CTG combo × SWP value, then record which canonical
            % labels survived as this iteration's fitSentinel. Cheaper than
            % re-deriving from HDF5 and lossless — the global alignment in
            % compileSTAT already pooled real duplicates trial-locally; this
            % only removes positions no trial here ever had data for.
            sentinel = struct();
            if ~isempty(regDim)
                [STAT_si, sentinel] = cropCanonicalREG(STAT_si, regDim);
            end
            sentinels{si} = sentinel;

            % Terminal fill: no fit function downstream handles NaN input.
            % NaN only needed to exist to keep pooling/cropping unbiased —
            % resolve any still-scattered NaN (partial, not fully-absent,
            % positions) back to 0 right before building the design matrix.
            STAT_si.df = cellfun(@zeroFillRemainingNaN, STAT_si.df, 'UniformOutput', false);

            for k = 1:nFolds
                mdlObj.trainMask = logical(trainMasks{k});
                mdlObj.STAT      = STAT_si;

                % Real fold
                mdlObj.getDesignMatrix();
                mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                scores(k, 1, :, si) = scoreFold(mdlObj, tVar, isCont, nTime);

                % Permutation null
                for p = 1:nPermute
                    mdlObj.TRAIN.STAT = shuffleTrialLabels(mdlObj.TRAIN.STAT, tVar);
                    mdlObj.DM         = dmFcn(mdlObj);
                    mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                    scores(k, 1+p, :, si) = scoreFold(mdlObj, tVar, isCont, nTime);
                end
            end
        end

        % ── 5d. Re-fit on full CTG data so transform path is valid ───────────
        % Uncropped (full global canonical width, per compileSTAT) — this is
        % the artifact future inference projects onto, so it keeps the wide
        % canonical axis rather than any one SWP iteration's tightened crop.
        % Still needs terminal NaN resolution since alignCoAxes NaN-fills.
        STAT_ctg.df      = cellfun(@zeroFillRemainingNaN, STAT_ctg.df, 'UniformOutput', false);
        mdlObj.STAT      = STAT_ctg;
        mdlObj.trainMask = true(nTrials, 1);
        mdlObj.getDesignMatrix();
        mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
        mdlObj.trainMask = [];

        % ── 5e. Pack result DF ────────────────────────────────────────────────
        if hasSwp
            % Unflatten the combo dim into one trailing dim per SWP axis —
            % column-major reshape matches swpLinToSubs's own mixed-radix
            % decomposition (axis 1 varies fastest), so combo si and
            % subscript (i1,...,iA) always refer to the same slice.
            scores = reshape(scores, [nFolds, 1+nPermute, nTime, nSwpPerAxis]);
        else
            scores = scores(:,:,:,1);   % drop SWP singleton
        end

        R     = struct();
        R.df  = scores;
        R.ax.fold    = (1:nFolds)';
        % Named "perm", not "permute" — a dynamicprops field literally named
        % 'permute' collides with MATLAB's generic array-reordering
        % permute() once nex_initAxisPointer_v2 wraps R.ptr into a
        % nexObj_ptr (handle & dynamicprops): the assignment resolves as a
        % method call instead of a property write ("Assignment not
        % supported because the result of method 'permute' is a temporary
        % value").
        R.ax.perm = ["real", compose("null_%03d", 1:nPermute)];
        if ~strcmp(dn, "None")
            R.ax.(dn) = dnAx;   % dn = domain.DN(1) — not necessarily "t"
        end
        if hasSwp
            for a = 1:numel(swpAxes)
                R.ax.(char(swpAxes(a).id)) = swpAxes(a).vals;
            end
        end
        R = nex_initAxisPointer_v2(R);
        R.fitSentinel = sentinels;   % {1×nSwp} cell, one struct per SWP combo

        % ── 5f. Build result STAT row ─────────────────────────────────────────
        row = table({R.df}, {R.ax}, {R.ptr}, {R.fitSentinel}, ...
                     'VariableNames', {'df','ax','ptr','fitSentinel'});
        if ~isempty(validCTG)
            row = [comboTbl(ci,:), row]; %#ok<AGROW>
        end
        resultRows{ci} = row;
    end

    % ── 6. Restore STAT; assemble RESULT table ───────────────────────────────
    mdlObj.STAT = STAT_full;

    resultRows = resultRows(~cellfun(@isempty, resultRows));
    if isempty(resultRows)
        fprintf('[nexAnalysis_cvPermute] no results produced.\n');
        return;
    end
    RESULT = vertcat(resultRows{:});

    if ismethod(mdlObj, 'storeResult')
        mdlObj.storeResult(resultID, RESULT);
    else
        mdlObj.RESULTS.(resultID) = RESULT;
    end

    if isfield(cvCfg, 'resultsPath') && ~isempty(cvCfg.resultsPath)
        [pDir,~,~] = fileparts(cvCfg.resultsPath);
        if ~isfolder(pDir), mkdir(pDir); end
        save(cvCfg.resultsPath, 'RESULT');
        fprintf('[nexAnalysis_cvPermute] saved → %s\n', cvCfg.resultsPath);
    end
    fprintf('[nexAnalysis_cvPermute] done — %s  (%d rows)\n', resultID, height(RESULT));
end


% ── Resolve the DF dimension an axis's data actually lives on ────────────────
% Mirrors the REG/FTR resolution inside nexOp_alignCoAxes: a co-indexed label
% (e.g. 'chans' riding on 'unit') has ptr.(axisName).dim == [] — find the
% co-indexed sibling that owns a real dimension instead.
%
% ptr is an axis-pointer object, not a plain struct — isfield() always
% returns false for non-struct types even when the property genuinely
% exists (fieldnames()/dynamic dot-access work fine on objects; isfield()
% is struct-only). Must check membership against fieldnames(ptr) instead,
% or this silently fails to resolve anything and always returns [].
function dim = resolveAxisDim(ax, ptr, axisName)
    axisName  = char(axisName);
    dim       = [];
    ptrFields = fieldnames(ptr);
    if ismember(axisName, ptrFields) && ~isempty(ptr.(axisName).dim)
        dim = ptr.(axisName).dim;
        return;
    end
    coIdx = nexOp_coIndexPairs(ax);
    for p = 1:numel(coIdx)
        pair = coIdx{p};
        if ~ismember(axisName, pair), continue; end
        for m = 1:numel(pair)
            cand = char(pair{m});
            if strcmp(cand, axisName), continue; end
            if ismember(cand, ptrFields) && ~isempty(ptr.(cand).dim)
                dim = ptr.(cand).dim;
                return;
            end
        end
    end
end


% ── Decompose a flat combo index into one subscript per SWP axis ─────────────
% Column-major (mixed-radix) decomposition — axis 1 varies fastest — the same
% convention MATLAB's own reshape/ind2sub use, so a `scores` array flattened
% during the fold loop reshapes back to N-D (step 5e) with combo si and
% subs(a) always referring to the same slice. Works for any number of axes,
% including zero-length dims (single-axis SWP, or no SWP at all via si==1).
function subs = swpLinToSubs(si, dims)
    nd   = numel(dims);
    subs = ones(1, nd);
    rem  = si - 1;
    for d = 1:nd
        subs(d) = mod(rem, dims(d)) + 1;
        rem     = floor(rem / dims(d));
    end
end


% ── Crop REG-canonical positions that are NaN (structurally absent) for ─────
% every trial in STAT_in, along `dim`. Lossless: the global alignment in
% compileSTAT already pooled real duplicates trial-locally, so a position
% that's NaN everywhere here genuinely has no data for this CTG×SWP slice.
% Returns the cropped STAT and a sentinel struct of the canonical labels
% (one field per axis riding on `dim`) that survived the crop.
function [STAT_out, sentinel] = cropCanonicalREG(STAT_in, dim)
    STAT_out = STAT_in;
    sentinel = struct();
    dfs = STAT_in.df;
    if isempty(dfs) || isempty(dim), return; end

    nd        = ndims(dfs{1});
    otherDims = setdiff(1:nd, dim);

    allNaN = [];
    for i = 1:numel(dfs)
        if isempty(otherDims)
            m = isnan(dfs{i});
        else
            m = all(isnan(dfs{i}), otherDims);
        end
        m = reshape(m, [], 1);
        if isempty(allNaN), allNaN = m; else, allNaN = allNaN & m; end
    end
    keepMask = ~allNaN;
    if all(keepMask), return; end   % nothing to crop

    ax0     = STAT_in.ax(1);
    ptr0    = STAT_in.ptr(1);
    axNames = fieldnames(ax0);
    ridingAxes = {};
    for f = axNames'
        fld = f{1};
        d = resolveAxisDim(ax0, ptr0, fld);
        if isequal(d, dim) && numel(ax0.(fld)) == numel(keepMask)
            sentinel.(fld) = ax0.(fld)(keepMask);
            ridingAxes{end+1} = fld; %#ok<AGROW>
        end
    end

    for i = 1:height(STAT_out)
        A = STAT_out.df{i};
        S = repmat({':'}, 1, nd);
        S{dim} = keepMask;
        STAT_out.df{i} = A(S{:});
        ax_i = STAT_out.ax(i);
        for f = ridingAxes
            ax_i.(f{1}) = ax_i.(f{1})(keepMask);
        end
        STAT_out.ax(i) = ax_i;
    end
end


% ── Resolve any surviving NaN (partial, not fully-absent, positions) to 0 ───
% before a design matrix is built — no fit function in this pipeline handles
% NaN input.
function A = zeroFillRemainingNaN(A)
    A(isnan(A)) = 0;
end


% ── Match raw SWP labels against one unique value (cell/string/numeric) ──────
function mask = matchesSWPValue(vals, target)
    if iscell(target), target = target{1}; end
    if iscell(vals)
        mask = strcmp(vals, target);
    else
        mask = vals == target;
    end
end


% ── Slice all trial dfs along a given dimension at index si ──────────────────
function STAT_out = sliceSTAT(STAT_in, dim, si)
    STAT_out    = STAT_in;
    STAT_out.df = cellfun(@(df) sliceDim(df, dim, si), STAT_in.df, 'UniformOutput', false);
end

function X = sliceDim(A, dim, idx)
    % Deliberately not squeezed: collapsing this singleton would shift every
    % higher dimension index down by one, invalidating any .ptr.(axis).dim
    % computed against the pre-slice array (dnDim in scoreFold, regDim in
    % cropCanonicalREG, etc). A leftover size-1 dim is inert for every
    % dimension-name-relative consumer downstream (permute/reshape/cell2mat).
    S      = repmat({':'}, 1, ndims(A));
    S{dim} = idx;
    X      = A(S{:});
end


% ── Score one fold: time-resolved predictions ─────────────────────────────────
function score = scoreFold(mdlObj, tVar, isCont, nTime)
    STAT_test = mdlObj.TEST.STAT;

    if isstruct(mdlObj.W) && isfield(mdlObj.W, 'scoreFn') && ~isempty(mdlObj.W.scoreFn)
        score = mdlObj.W.scoreFn(STAT_test, tVar);
        return;
    end

    Y_trial = STAT_test.(tVar);
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    nTest = numel(STAT_test.df);

    if isstruct(mdlObj.W) && isfield(mdlObj.W, 'buildTestX') && ~isempty(mdlObj.W.buildTestX)
        X_test = mdlObj.W.buildTestX(STAT_test);
        Y_pred = mdlObj.predict(X_test);
        if isCont
            cc = corrcoef(double(Y_trial(:)), double(Y_pred(:)));
            sc = cc(1,2)^2;
        else
            sc = balancedAccuracy(string(Y_trial(:)), Y_pred);
        end
        score = repmat(sc, nTime, 1);
        return;
    end

    dn = char(mdlObj.domain.DN(1));
    if strcmp(dn, "None")
        % No training-domain axis. nexOp_stackSTAT has no notion of
        % domain.DN at all — it always keeps dim 2 of each trial's df as
        % the feature axis and flattens every OTHER dim (including whatever
        % dim 1 naturally is) into stacked rows. For a genuinely
        % already-collapsed source that's a no-op (one row per trial); for
        % a raw, not-yet-embedded source it still expands dim 1 into many
        % rows per trial, same as training does via stat2dm_supervised.
        % Training doesn't care about that multiplier because it builds X
        % AND Y from the same stacking, so they stay self-consistent
        % regardless — pull Y from that same G_stack here too instead of
        % assuming one row per trial, so X_test/Y_trial/nTest can't diverge
        % from whatever predict() actually sees.
        [X_test, G_test] = nexOp_stackSTAT(STAT_test);
        Y_trial = G_test.(tVar);
        if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
        nTest = size(X_test, 1);
        nTime = 1;
    else
        dnDim = STAT_test.ptr(1).(dn).dim;
        if dnDim == 1
            X_test = cell2mat(STAT_test.df);
        else
            order  = [dnDim, setdiff(1:ndims(STAT_test.df{1}), dnDim)];
            X_test = cell2mat(cellfun(@(df) permute(df, order), ...
                              STAT_test.df, 'UniformOutput', false));
        end
        X_test = reshape(X_test, nTest * nTime, []);
    end

    try
        Y_pred_flat = mdlObj.predict(X_test);
    catch e
        fprintf('[nexAnalysis_cvPermute] scoreFold: predict() failed — X_test is %s.\n', mat2str(size(X_test)));
        disp(getReport(e));
        keyboard
    end

    if isCont
        Y_pred_mat = reshape(double(Y_pred_flat), nTime, nTest)';
        Y_true     = double(Y_trial(:));
        score = arrayfun(@(t) localCorrR2(Y_true, Y_pred_mat(:,t)), 1:nTime)';
    else
        Y_pred_mat = reshape(Y_pred_flat, nTime, nTest)';
        Y_true     = string(Y_trial(:));
        score = arrayfun(@(t) balancedAccuracy(Y_true, Y_pred_mat(:,t)), 1:nTime)';
    end
end

function r2 = localCorrR2(a, b)
    cc = corrcoef(double(a(:)), double(b(:)));
    r2 = cc(1,2)^2;
end


% ── Permute trial-level Y labels within STAT (copy, not in-place) ────────────
function STAT_out = shuffleTrialLabels(STAT_in, tVar)
    STAT_out        = STAT_in;
    nTrials         = height(STAT_in);
    STAT_out.(tVar) = STAT_in.(tVar)(randperm(nTrials));
end


% ── Macro-average recall (balanced accuracy for categorical targets) ──────────
function score = balancedAccuracy(Y_true, Y_pred)
    classes = unique(Y_true);
    recalls = zeros(numel(classes), 1);
    for c = 1:numel(classes)
        mask       = Y_true == classes(c);
        recalls(c) = mean(Y_pred(mask) == classes(c));
    end
    score = mean(recalls);
end
