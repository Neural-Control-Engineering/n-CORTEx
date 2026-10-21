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

    % Opt-in audit trail — cvCfg.auditDir set (non-empty path) writes a full
    % step-by-step record (shapes, content summaries, quantization edges,
    % SWP window/block ranges, per-block PCA variance, a single traced
    % trial's data at each transform stage) to
    % <auditDir>/nexAudit_<resultID>/, organized to mirror this function's
    % own section numbering, instead of printing to the console — see the
    % nexAudit_writeText/nexAudit_savePlot helpers. Zero overhead and zero
    % behavior change when auditDir is unset (the default) — every audit
    % call below is gated on auditOn.
    auditOn  = isfield(cvCfg, 'auditDir') && ~isempty(cvCfg.auditDir);
    auditDir = '';
    if auditOn
        auditDir = fullfile(cvCfg.auditDir, sprintf('nexAudit_%s', resultID));
        if ~isfolder(auditDir), mkdir(auditDir); end
        fprintf('[nexAnalysis_cvPermute] audit trail -> %s\n', auditDir);
    end

    % ── 1. Compile full STAT ─────────────────────────────────────────────────
    [STAT_full, idxSel, drop] = mdlObj.compileSTAT();
    tVar = char(mdlObj.dfID_target);
    if ~ismember(tVar, STAT_full.Properties.VariableNames)
        Y_tmp = dtsIO_readTF(mdlObj.nexon, tVar, idxSel, 'simple');
        Y_tmp = Y_tmp(~drop);
        STAT_full.(tVar) = Y_tmp;
    end

    % Coerce a numeric-looking non-double tVar (e.g. read back as a string
    % array) to double once, here, so it propagates correctly to
    % everything downstream: isCont below, stat2dm_supervised/
    % nexOp_quantizeY's own isnumeric gates, and G_train_p.(tVar) (which
    % just reads through whatever type STAT_full.(tVar) was, via
    % nexOp_stackByFTR). Same coercion convention nexObject.reportAverage
    % already uses for STAT columns. isnumeric(string(...)) is always
    % false regardless of content, so this can't be caught downstream by
    % "is it numeric" checks alone — it has to be fixed at the source.
    rawTVar = STAT_full.(tVar);
    if ~isnumeric(rawTVar)
        numTry = str2double(string(rawTVar));
        if any(~isnan(numTry)), STAT_full.(tVar) = numTry; end
    end

    if auditOn, nexAudit_section1_compileSTAT(auditDir, STAT_full, tVar); end

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

    if auditOn, nexAudit_section2_ctgCombos(auditDir, comboTbl, nCombos, height(STAT_full)); end

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

    % Candidate-value discovery below (both getBinEdges calls just ahead)
    % runs ONCE, globally, over the full (possibly multi-subject)
    % STAT_full.ax(1) — i.e. whichever subject happens to be row 1. Pass
    % every subject actually present so the candidate SWP value LIST
    % (e.g. which regions exist to sweep over) is comprehensive across
    % subjects, not just row 1's — resolveSubjectMap_ merges multiple
    % subjects' regMaps the same way nexOp_selectedSubjectsRegMap.m
    % already does (Nexus WIP.md #10). The actual per-combo/per-subject
    % REGION ASSIGNMENT for real data stays correctly subject-scoped via
    % fitReduce/applyReduce's own dispatch, unaffected by this — this is
    % purely about not under-discovering candidate values to sweep.
    swpSubjAll = string.empty;
    if ismember('subj_internal', STAT_full.Properties.VariableNames)
        swpSubjAll = unique(string(STAT_full.subj_internal));
    end

    % A reduce-mode FTR axis means dimensionality reduction must run before
    % any pool-mode axis collapses samples it needs at full resolution (see
    % WIP.md #3) — nexOp_compileSTAT already skips ALL pMap pooling/
    % relabeling when this is true, so STAT_full's df/ax are still fully
    % raw for every pMap axis, INCLUDING the reduce-mode axis's own labels
    % (normally relabeled to region names by nexOp_poolAxes; here it never
    % ran, so those axis values are still raw unit IDs). Detected the same
    % way initReducer/nexOp_compileSTAT already do.
    needsHR = false;
    if ~isempty(mdlObj.pMap)
        pmFields = fieldnames(mdlObj.pMap);
        needsHR  = any(arrayfun(@(i) mdlObj.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
    end
    ftrAxisStr = string(mdlObj.domain.FTR(1));
    poolAxis   = "";
    if needsHR
        poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
        fprintf(['[nexAnalysis_cvPermute] needsHR: FTR axis "%s" is reduce-mode; ' ...
                 'deferring pool axis "%s" until after reduction.\n'], ftrAxisStr, poolAxis);
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
    swpAxes  = struct('id', {}, 'raw', {}, 'vals', {}, 'dim', {}, 'n', {}, 'coField', {}, 'rangeLabel', {});
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
        if needsHR && id == ftrAxisStr
            % This SWP axis IS the reduce-mode FTR axis. Its real SWP
            % granularity, post-reduction, is one value per BLOCK
            % (pm.getBinEdges' own binLabels — e.g. one per region), not
            % one per raw unit ID — raw is still fully raw here since
            % needsHR skipped relabeling entirely. Must match
            % nexHR_blockColRanges' own labeling exactly, or SWP combo
            % selection can never find its block downstream.
            %
            % pMap is typically configured on FTR's co-indexed PRIMARY
            % sibling (e.g. domain.REG='chans', physical position — what
            % region boundaries are defined against), not FTR itself (e.g.
            % 'unit', identity only) — same resolution fitReduce uses, and
            % binning must use the PRIMARY axis's own values, not raw
            % (which is FTR's/unit's).
            [pm_id, pmKey] = nexOp_resolvePMapEntry(mdlObj.pMap, char(id), STAT_full.ax(1));
            if isempty(pm_id)
                warning('[nexAnalysis_cvPermute] SWP axis "%s" has no pMap entry, directly or via a co-indexed sibling — dropping it from the sweep.', id);
                continue;
            end
            primaryVals = STAT_full.ax(1).(pmKey);
            [~, ~, blockLabels] = pm_id.getBinEdges(primaryVals, abs(pm_id.divsPerBin), swpSubjAll);
            vals = unique(blockLabels, 'stable');
            % Narrow to whatever the user currently has selected in the
            % Pointer bus for this axis (e.g. "STN, HY" only) — this is
            % what makes the sweep actually respect Pointer, rather than
            % always sweeping every detected block. applyPointerDM is the
            % DM-level counterpart to mdlObject.applyPointer: it filters
            % candidate SWP values already resolved to reduce/pool
            % granularity, instead of slicing raw STAT positions (which is
            % what applyPointer itself does, and why it can't do this job
            % for needsHR — see its own type-mismatch-skip comment).
            vals = mdlObj.applyPointerDM(id, vals, STAT_full.ax(1));
            % Block/region NAME already is its own label — no numeric
            % range concept for this axis (audit trail only).
            rangeLbl = vals;
        elseif needsHR && poolAxis ~= "" && id == poolAxis
            % This SWP axis IS the deferred pool-mode axis. Its real SWP
            % granularity, post-pooling, is one value per WINDOW
            % (pm.getBinEdges' own binIDs — axID-mode bin-start
            % representative), not one per raw timepoint — raw is still
            % fully raw here since needsHR defers pooling entirely. Must
            % match nexOp_poolStackedDM's own binIDs assignment to
            % G.(poolAxis) exactly, or SWP combo selection can never find
            % its window downstream.
            pm_id = mdlObj.pMap.(char(id));
            [~, binIDs, binLabels] = pm_id.getBinEdges(raw, abs(pm_id.divsPerBin), swpSubjAll);
            [uBinIDs, firstIdx] = unique(binIDs, 'stable');
            uBinLabels = binLabels(firstIdx);   % "start--end" per window, same
                                                 % order/alignment as uBinIDs —
                                                 % audit trail only (see
                                                 % nexOp_getBinEdges's own
                                                 % compose("%d--%d",...) output)
            vals = uBinIDs;
            vals = mdlObj.applyPointerDM(id, vals, STAT_full.ax(1));
            % Re-derive labels for whichever vals survived Pointer
            % narrowing, keeping label<->value alignment correct.
            [~, locIdx] = ismember(vals, uBinIDs);
            rangeLbl = uBinLabels(locIdx);
        else
            vals = unique(raw, 'stable');
            rangeLbl = string(vals);
        end
        % Co-indexed sibling field to ALSO pack these SAME vals into R.ax
        % under (e.g. "chans" alongside "unit") — resolved generically
        % from vals' own type, not from which branch above produced it:
        % needsHR's block labels, and regular (non-needsHR) mapID pooling
        % upstream in nexOp_compileSTAT, both relabel co-indexed siblings
        % to the SAME shared region-label string at every position, so
        % duplicating vals verbatim under the sibling's name is correct
        % either way. Raw/unpooled numeric IDs are only position-aligned
        % across siblings (unit=42 can sit at the same position as
        % chans=7, not the same VALUE) — see resolveCoIndexedSiblingIfLabeled.
        coField = resolveCoIndexedSiblingIfLabeled(id, vals, STAT_full.ax(1));
        swpAxes(end+1) = struct('id', id, 'raw', raw, 'vals', vals, ...
                                 'dim', dim, 'n', numel(vals), 'coField', coField, ...
                                 'rangeLabel', rangeLbl); %#ok<AGROW>
    end
    hasSwp = ~isempty(swpAxes);

    if auditOn, nexAudit_section4_swpAxes(auditDir, swpAxes); end

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

        % Filesystem-safe combo directory name, reused by every audit write
        % for the rest of this combo's iteration.
        comboDir = sprintf('combo_%s', regexprep(ctgLabel, '[\\/:*?"<>| ]+', '_'));
        if auditOn
            nexAudit_comboSummary(auditDir, comboDir, ci, nCombos, ctgLabel, nTrials, tVar, STAT_ctg.(tVar));
        end

        % ── 5b. Y labels + fold allocation ───────────────────────────────────
        Y_ctg = STAT_ctg.(tVar);
        if iscell(Y_ctg), Y_flat = [Y_ctg{:}]'; else, Y_flat = Y_ctg(:); end
        isCont = isnumeric(Y_flat);

        % Quantize once here — trial-level, whole combo — rather than each
        % fold re-deriving its own edges from a smaller, noisier train-only
        % subset later. edgesY_full/nBinsY are reused below by the needsHR
        % fold loop and the full-CTG refit (5d) instead of recomputing.
        nBinsY = Inf;
        try
            nBinsY = mdlObj.collector.Target.nBins;
        catch
        end
        edgesY_full = [];
        if isCont
            [Y_stratVar, edgesY_full] = nexOp_quantizeY(Y_flat, nBinsY);
        else
            Y_stratVar = Y_flat;
        end

        if isCont && isempty(edgesY_full)
            % No quantization in play (pass-through) — nothing to stratify
            % by, same plain random split as before.
            cv         = cvpartition(nTrials, 'KFold', nFolds);
            trainMasks = arrayfun(@(k) {training(cv, k)}, 1:nFolds);
        else
            % Stratified split — same allocator the already-categorical
            % branch always used (cvpartition(group,...) balances class
            % proportions across folds), now also reached for a quantized
            % continuous target so each fold's train/test set gets a
            % proportional share of low/mid/high values instead of
            % whatever a plain random draw happens to produce.
            trainMasks = nexStat_allocateFolds(Y_stratVar, nFolds);
        end

        % Diagnostic: per-fold train/test size + (categorical) class
        % breakdown of the TEST set — set once per CTG combo here, before
        % the SWP loop even starts, so a degenerate fold here (esp. an
        % EMPTY test set — the only way balancedAccuracy returns NaN, via
        % mean([])) shows up identically across every SWP combo downstream,
        % not something SWP-specific. Cheap, always-on: this is exactly
        % the kind of silent failure (too few trials for the requested
        % nFolds, producing a 0-test-trial fold for a stratified split)
        % that otherwise only shows up as suspiciously tiny/absent error
        % bars several steps downstream with nothing pointing back here.
        for k = 1:nFolds
            testMask = ~trainMasks{k};
            nTr = nnz(trainMasks{k});
            nTe = nnz(testMask);
            if isCont
                foldTxt = sprintf('fold %d/%d: train=%d test=%d\n', k, nFolds, nTr, nTe);
            else
                testY = Y_flat(testMask);
                if iscell(testY), testY = string(testY); end
                [uc, ~, ic] = unique(testY);
                counts    = accumarray(ic, 1);
                classStr  = strjoin(compose("%s=%d", string(uc), counts), ', ');
                if nTe == 0, classStr = '(empty)'; end
                foldTxt = sprintf('fold %d/%d: train=%d test=%d  test classes: %s\n', ...
                                   k, nFolds, nTr, nTe, classStr);
            end
            fprintf('[nexAnalysis_cvPermute]   %s', foldTxt);
            if auditOn
                nexAudit_writeText(auditDir, fullfile(comboDir, sprintf('fold_%d', k), 'summary.txt'), foldTxt);
            end
        end

        % ── 5c. fold × SWP × permute loop ────────────────────────────────────
        % fold is outermost (not nested inside SWP) so that, when needsHR,
        % the reduction basis is fit exactly once per fold — using ONLY
        % that fold's own training trials (no leakage) — and reused as-is
        % across every SWP combo and every permutation for that fold,
        % rather than refitting per SWP/permutation (which would both leak
        % and explode computationally; see WIP.md #3). trainMasks was
        % already computed once per CTG combo above and never depended on
        % SWP, so for the ~needsHR path this reorder changes iteration
        % order only — same computations, same results, bit-identical.
        scores    = nan(nFolds, 1 + nPermute, nTime, nSwp);
        % Feature weights — same (fold, realization, swp) grain as scores,
        % minus the nTime dimension: one fitted model per (k, j, si) gets
        % SCORED across every t at once (scoreFold/scoreFoldDM), so the
        % weights themselves don't vary across t within one fit, only
        % across which (fold, realization, swp) actually produced that
        % fit. Cell, not a preallocated numeric array, because the
        % needsHR path's feature-block sweeping can vary column count
        % per SWP combo — consolidated to a real array below only if
        % every populated cell agrees on nFeatures.
        Wcell     = cell(nFolds, 1 + nPermute, nSwp);
        sentinels = cell(1, nSwp);

        if ~needsHR
            % Precompute each SWP combo's sliced STAT once per CTG combo —
            % same timing/cost as before the reorder, just sitting one
            % level further out relative to fold (a cache, not new work).
            STAT_si_all = cell(1, nSwp);
            for si = 1:nSwp
                [STAT_si_all{si}, sentinels{si}] = sliceSWPCombo( ...
                    STAT_ctg, si, nSwp, swpAxes, nSwpPerAxis, hasSwp, regDim);
            end
        end
        % needsHR path: no REG/DF cropping applies (SWP is a column/row
        % select on the already-reduced+pooled {X,G}, not STAT slicing) —
        % sentinels stays {1×nSwp} of empty structs, same shape as before.

        for k = 1:nFolds
            mdlObj.trainMask = logical(trainMasks{k});

            if needsHR
                % ── Reduce (once per fold, train-only) + pool (after) ────────
                STAT_train = STAT_ctg(mdlObj.trainMask == 1, :);
                STAT_test  = STAT_ctg(mdlObj.trainMask == 0, :);
                fprintf(['[nexAnalysis_cvPermute] fold %d/%d: fitReduce on %d train ' ...
                         'trial(s), %d test trial(s)\n'], k, nFolds, height(STAT_train), height(STAT_test));
                % DIAGNOSTIC — confirm every row in this combo's training
                % set actually shares ONE subject's own canonical REG
                % width, rather than assuming combo masking (section 5a)
                % correctly isolated one subject's rows. If this prints
                % more than one (subj, width) pair for a combo whose CTG
                % includes subject, that's the leak, caught at the exact
                % row level rather than downstream inside nexHR_fit.
                try
                    regAxisDiag = char(mdlObj.domain.REG);
                    if ~strcmp(regAxisDiag, 'None') && isfield(STAT_train.ax(1), regAxisDiag) ...
                            && ismember('sessionLabel_subj', STAT_train.Properties.VariableNames)
                        widths  = arrayfun(@(a) numel(a.(regAxisDiag)), STAT_train.ax);
                        subjCol = STAT_train.sessionLabel_subj;
                        if iscell(subjCol), subjCol = string(subjCol); end
                        pairs = [string(subjCol), string(widths)];
                        [upairs, ~, ic] = unique(pairs, 'rows');
                        for r = 1:size(upairs, 1)
                            fprintf('[nexAnalysis_cvPermute]     DIAG: subj=%s %sWidth=%s rows=%d\n', ...
                                    upairs(r,1), regAxisDiag, upairs(r,2), sum(ic == r));
                        end
                    end
                catch e
                    fprintf('[nexAnalysis_cvPermute]     DIAG skipped: %s\n', e.message);
                end
                t0 = tic;
                [HR, layout, blockColRanges, X_train_r, G_train] = mdlObj.fitReduce(STAT_train);
                [X_test_r, G_test] = mdlObj.applyReduce(STAT_test, HR, layout);
                fprintf('[nexAnalysis_cvPermute] TIMING: fold %d/%d fitReduce+applyReduce took %.2f s\n', ...
                        k, nFolds, toc(t0));
                % fitReduce/applyReduce -> nexHR_fit/nexHR_transform spin up a
                % Python sklearn PCA object + numpy arrays PER BLOCK, every
                % fold — nothing in that path releases them (unlike
                % nexFit_specParam_parallel's own per-iteration py.gc.collect(),
                % the established precedent for exactly this under
                % ExecutionMode="OutOfProcess"). Left unchecked across a whole
                % run's worth of folds, the backlog isn't reclaimed until
                % MATLAB's own cleanup at some later point — bounding it to
                % one fold's worth here is what that pause was actually from.
                t0 = tic;
                try, py.gc.collect(); catch, end
                fprintf('[nexAnalysis_cvPermute] TIMING: fold %d/%d py.gc.collect() took %.2f s\n', ...
                        k, nFolds, toc(t0));

                if auditOn
                    nexAudit_blockVariance(auditDir, comboDir, k, HR, blockColRanges, ctgLabel);
                end

                if poolAxis ~= ""
                    [X_train_p, G_train_p] = nexOp_poolStackedDM(X_train_r, G_train, mdlObj.pMap, poolAxis);
                    [X_test_p,  G_test_p]  = nexOp_poolStackedDM(X_test_r,  G_test,  mdlObj.pMap, poolAxis);
                else
                    X_train_p = X_train_r; G_train_p = G_train;
                    X_test_p  = X_test_r;  G_test_p  = G_test;
                end
                fprintf('[nexAnalysis_cvPermute] fold %d/%d: pooled train X %s, test X %s\n', ...
                        k, nFolds, mat2str(size(X_train_p)), mat2str(size(X_test_p)));

                % Quantize Y using the SAME combo-level edges for every
                % fold (computed once in 5b, from the full combo's
                % trial-level Y) instead of each fold re-deriving its own
                % from that fold's own (smaller, train-only) pooled Y —
                % which let bin boundaries drift fold-to-fold, so "quantile
                % 1" meant a different physical range in each fold.
                % edges=[] (pass-through) still behaves exactly as before.
                %
                % tVar can come back cell-wrapped (same reason Y_ctg/Y_flat
                % and scoreFold's own Y_trial unwrap it elsewhere in this
                % file).
                Y_train_raw = G_train_p.(tVar);
                if iscell(Y_train_raw), Y_train_raw = [Y_train_raw{:}]'; end
                Y_test_raw = G_test_p.(tVar);
                if iscell(Y_test_raw), Y_test_raw = [Y_test_raw{:}]'; end

                edgesY = edgesY_full;
                if isempty(edgesY)
                    Y_train_q = Y_train_raw;
                    Y_test_q  = Y_test_raw;
                else
                    Y_train_q = discretize(double(Y_train_raw), edgesY);
                    Y_test_q  = discretize(double(Y_test_raw), edgesY);
                end
                isCont_fold = isCont && isempty(edgesY);
                fprintf(['[nexAnalysis_cvPermute] fold %d/%d: nBinsY=%s, edgesY=%s, ' ...
                         'unique(Y_train_q)=%s (n=%d), isCont_fold=%d\n'], ...
                        k, nFolds, mat2str(nBinsY), mat2str(edgesY), ...
                        mat2str(unique(Y_train_q)'), numel(unique(Y_train_q)), isCont_fold);

                if auditOn
                    nexAudit_quantizeEdges(auditDir, comboDir, k, tVar, nBinsY, edgesY, Y_train_raw, ctgLabel);
                end

                for si = 1:nSwp
                    [keepColsTrain, keepColsTest, keepRowsTrain, keepRowsTest, comboLabel] = ...
                        resolveSWPMaskHR(si, nSwpPerAxis, swpAxes, hasSwp, ftrAxisStr, poolAxis, ...
                                          blockColRanges, G_train_p, G_test_p);
                    fprintf('[nexAnalysis_cvPermute]   fold %d/%d combo %d/%d: %s\n', ...
                            k, nFolds, si, nSwp, comboLabel);

                    X_tr = X_train_p(keepRowsTrain, keepColsTrain);
                    Y_tr = Y_train_q(keepRowsTrain);
                    X_te = X_test_p(keepRowsTest, keepColsTest);
                    Y_te = Y_test_q(keepRowsTest);
                    fprintf('[nexAnalysis_cvPermute]     X_tr %s, X_te %s\n', mat2str(size(X_tr)), mat2str(size(X_te)));

                    if size(X_tr, 2) == 0
                        % 0 surviving features — e.g. a region block that
                        % reduced to zero components (no units left after
                        % SWP/Pointer narrowing this fold's own training
                        % rows). Nothing to fit at all; attempting it
                        % doesn't even reach the degenerate-scatter case
                        % above, it fails earlier inside nexFit_lda's own
                        % reshape (numpy: "cannot reshape array of size 0").
                        % Same "leave W/score at their pre-allocated no-data
                        % fill and move on" handling as a degenerate fit,
                        % just caught before ever calling into Python.
                        fprintf('[nexAnalysis_cvPermute]     0 features, skipping fit (real + %d null(s))\n', nPermute);
                    else
                        % Real fold — DM already built (X/Y in hand), bypass
                        % dmFcn/getDesignMatrix entirely.
                        mdlObj.DM = nexOp_buildSupervisedDM(X_tr, Y_tr, tVar, edgesY);
                        try
                            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                            Wcell{k, 1, si} = mdlObj.getFeatureWeights().coef;
                            scores(k, 1, :, si) = scoreFoldDM(mdlObj, X_te, Y_te, isCont_fold);
                        catch e
                            % Degenerate fit — e.g. a single-surviving-feature
                            % SWP combo (a region block reduced to 1 component)
                            % whose within-class scatter isn't positive-
                            % definite for the LDA eigen solver ("leading minor
                            % of order 1 of B is not positive definite"). Leave
                            % this fold/combo's W/score at their pre-allocated
                            % "no data" fill (Wcell stays [], scores stays NaN
                            % — both already handled by every downstream
                            % consumer, see Wfull's own NaN-pad comment below)
                            % and move on, rather than aborting the entire CV
                            % run over one unfittable combo. Any OTHER error —
                            % a genuinely different bug — is not this case and
                            % must keep propagating, not get silently eaten.
                            if ~isDegenerateScatterError(e), rethrow(e); end
                            fprintf('[nexAnalysis_cvPermute]     fit failed, skipping: %s\n', e.message);
                        end

                        % Permutation null — reuse the SAME X_tr (never rebuilt;
                        % reduction is unsupervised, independent of Y), only Y
                        % gets reshuffled. Null weights captured too (not just
                        % null scores) — a genuine null baseline for the weight
                        % vector itself, not just for accuracy.
                        for p = 1:nPermute
                            Y_tr_p = Y_tr(randperm(numel(Y_tr)));
                            mdlObj.DM = nexOp_buildSupervisedDM(X_tr, Y_tr_p, tVar, edgesY);
                            try
                                mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                                Wcell{k, 1+p, si} = mdlObj.getFeatureWeights().coef;
                                scores(k, 1+p, :, si) = scoreFoldDM(mdlObj, X_te, Y_te, isCont_fold);
                            catch e
                                if ~isDegenerateScatterError(e), rethrow(e); end
                                fprintf('[nexAnalysis_cvPermute]     null fit failed, skipping: %s\n', e.message);
                            end
                        end
                    end
                end
            else
                % ── Existing path, unchanged, visited per (fold, then SWP) ───
                for si = 1:nSwp
                    STAT_si     = STAT_si_all{si};
                    mdlObj.STAT = STAT_si;

                    % Real fold
                    mdlObj.getDesignMatrix();
                    if nexFeatCount(mdlObj.DM) == 0
                        % See the needsHR branch's own comment on this same
                        % guard — 0 surviving features fails earlier than
                        % the degenerate-scatter case (inside nexFit_lda's
                        % own reshape), so it's caught here instead of via
                        % the catch block below.
                        fprintf('[nexAnalysis_cvPermute]     0 features, skipping fit (real + %d null(s))\n', nPermute);
                    else
                        try
                            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                            Wcell{k, 1, si} = mdlObj.getFeatureWeights().coef;
                            scores(k, 1, :, si) = scoreFold(mdlObj, tVar, isCont, nTime);
                        catch e
                            % See the needsHR branch's own comment on this same
                            % pattern — degenerate (e.g. single-feature) fits
                            % leave W/score at their pre-allocated "no data"
                            % fill and the run continues; anything else rethrows.
                            if ~isDegenerateScatterError(e), rethrow(e); end
                            fprintf('[nexAnalysis_cvPermute]     fit failed, skipping: %s\n', e.message);
                        end

                        % Permutation null — weights captured too, see the
                        % needsHR branch's own comment on why.
                        for p = 1:nPermute
                            mdlObj.TRAIN.STAT = shuffleTrialLabels(mdlObj.TRAIN.STAT, tVar);
                            mdlObj.DM         = dmFcn(mdlObj);
                            try
                                mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                                Wcell{k, 1+p, si} = mdlObj.getFeatureWeights().coef;
                                scores(k, 1+p, :, si) = scoreFold(mdlObj, tVar, isCont, nTime);
                            catch e
                                if ~isDegenerateScatterError(e), rethrow(e); end
                                fprintf('[nexAnalysis_cvPermute]     null fit failed, skipping: %s\n', e.message);
                            end
                        end
                    end
                end
            end
        end

        % ── 5d. Re-fit on full CTG data so transform path is valid ───────────
        % Uncropped (full global canonical width, per compileSTAT) — this is
        % the artifact future inference projects onto, so it keeps the wide
        % canonical axis rather than any one SWP iteration's tightened crop.
        % Still needs terminal NaN resolution since alignCoAxes NaN-fills.
        STAT_ctg.df = cellfun(@zeroFillRemainingNaN, STAT_ctg.df, 'UniformOutput', false);
        if needsHR
            % TIMING: isolate the full-CTG fitReduce, the gc.collect() call
            % itself, and the final fit — one of these is the "end of run"
            % delay; this pins down which, instead of guessing further.
            t0 = tic;
            [~, ~, blockColRanges_full, X_full_r, G_full] = mdlObj.fitReduce(STAT_ctg);
            fprintf('[nexAnalysis_cvPermute] TIMING: full-CTG fitReduce took %.2f s\n', toc(t0));
            t0 = tic;
            try, py.gc.collect(); catch, end   % see fold-loop's own comment on this
            fprintf('[nexAnalysis_cvPermute] TIMING: py.gc.collect() took %.2f s\n', toc(t0));
            if poolAxis ~= ""
                [X_full_p, G_full_p] = nexOp_poolStackedDM(X_full_r, G_full, mdlObj.pMap, poolAxis);
            else
                X_full_p = X_full_r; G_full_p = G_full;
            end

            if auditOn
                % Single-trial trace: same first trial of this combo, shown
                % raw -> post block-PCA reduction -> post-pooling. Traced
                % through the FULL-CTG refit (all trials, one canonical
                % basis) rather than any one fold's own basis, which would
                % differ fold-to-fold depending on which other trials were
                % in that fold's training set — a different question than
                % "is the transform pipeline clobbering data." Orientation
                % normalization needs resolveAxisDim, a local function
                % private to this file, so it stays here rather than
                % moving into the (separate-file) audit helper.
                trialRow = 1;
                rawDf  = STAT_ctg.df{trialRow};
                ftrDim = resolveAxisDim(STAT_ctg.ax(trialRow), STAT_ctg.ptr(trialRow), ftrAxisStr);
                if ~isempty(ftrDim) && ftrDim == 1
                    rawDf = rawDf';   % normalize to [time x unit], matching stage 2/3's [row x reduced-feature] convention
                end
                nexAudit_singleTrialTrace(auditDir, comboDir, ctgLabel, trialRow, rawDf, ...
                    X_full_r, G_full, X_full_p, G_full_p, blockColRanges_full);
            end

            % Reuse the SAME combo-level edges from 5b (rather than
            % recomputing from the full-CTG pooled Y here) so the final
            % artifact-producing fit uses identical bin boundaries to every
            % fold above.
            Y_full_raw = G_full_p.(tVar);
            if iscell(Y_full_raw), Y_full_raw = [Y_full_raw{:}]'; end
            if isempty(edgesY_full)
                Y_full_q = Y_full_raw;
            else
                Y_full_q = discretize(double(Y_full_raw), edgesY_full);
            end
            mdlObj.DM = nexOp_buildSupervisedDM(X_full_p, Y_full_q, tVar, edgesY_full);
            t0 = tic;
            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
            fprintf('[nexAnalysis_cvPermute] TIMING: final full-CTG fit took %.2f s\n', toc(t0));
        else
            mdlObj.STAT      = STAT_ctg;
            mdlObj.trainMask = true(nTrials, 1);
            mdlObj.getDesignMatrix();
            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
        end
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

        % Consolidate Wcell into a real array, same reshape/drop treatment
        % as scores just above (minus the nTime dim — see Wcell's own
        % declaration comment for why weights don't carry one). nFeatures
        % is the MAX width across every populated cell — the needsHR
        % feature-block sweep can legitimately produce a NARROWER coef_
        % for a smaller region (nexHR_fit's nComp_actual clamps to
        % min(reducerDim, that region's own available units/samples)), not
        % a data error — so a shorter cell is PADDED with NaN up to the
        % max width rather than dropping the whole CTG combo's W the way
        % this used to. NaN, not zero, so a real near-zero weight is never
        % confused with "this region didn't have this many components" —
        % every NaN-aware downstream consumer (mean/std 'omitnan', etc.)
        % already treats it correctly as "no data" at that position.
        hasW = false; Wfull = []; nFeatures = 0;
        nonEmptyIdx = find(~cellfun(@isempty, Wcell));
        if ~isempty(nonEmptyIdx)
            nFeatures = max(cellfun(@numel, Wcell(nonEmptyIdx)));
            Wfull = nan(nFeatures, nFolds, 1+nPermute, nSwp);
            for k2 = 1:nFolds
                for j2 = 1:(1+nPermute)
                    for si2 = 1:nSwp
                        c = Wcell{k2, j2, si2};
                        if ~isempty(c), Wfull(1:numel(c), k2, j2, si2) = c(:); end
                    end
                end
            end
            hasW = true;
        end
        if hasW
            if hasSwp
                Wfull = reshape(Wfull, [nFeatures, nFolds, 1+nPermute, nSwpPerAxis]);
            else
                Wfull = Wfull(:,:,:,1);
            end
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
                if swpAxes(a).coField ~= ""
                    % Co-indexed sibling (e.g. "chans" alongside "unit") —
                    % same values under the sibling's own name, so a
                    % downstream consumer keying off either name finds a
                    % real axis. nex_initAxisPointer_v2 below already knows
                    % how to treat "chans" as a co-indexed LABEL (dim=[])
                    % riding on its same-length sibling's real dimension —
                    % see nex_coIndexAxisLabels — so this doesn't create a
                    % phantom extra array dimension.
                    R.ax.(char(swpAxes(a).coField)) = swpAxes(a).vals;
                end
            end
        end
        R = nex_initAxisPointer_v2(R);
        R.fitSentinel = sentinels;   % {1×nSwp} cell, one struct per SWP combo

        % Feature weights get their OWN (W, ax_W, ptr_W) triple, parallel
        % to (df, ax, ptr) rather than shoehorned into it — dimension
        % count/order genuinely differs (df: fold/perm/t/swp...; W:
        % feature/fold/perm/swp...). ax_W still SHARES fold/perm/swp's own
        % values with ax (same underlying fold/realization/combo
        % identities), only adding "feature" as a field ax never has.
        % Field-insertion order below matches Wfull's actual dimension
        % order (feature, fold, perm, swp...) on purpose —
        % nex_initAxisPointer_v2 matches ax fields to df dimensions by
        % length in field-iteration order, so this order is what keeps
        % the match unambiguous even if two fields' lengths coincide.
        if hasW
            ax_W = struct();
            ftrIsSwept = hasSwp && ismember(ftrAxisStr, string({swpAxes.id}));
            nSwpCols   = max(nSwp, 1);
            R.featureLabels = strings(nFeatures, nSwpCols);
            ax_W.feature    = (1:nFeatures)';   % fallback if blockColRanges_full unavailable

            % Two structurally different cases (Nexus WIP.md #11):
            %   - FTR not swept: there's exactly one combined feature
            %     vector (every region's/band's components laid out once,
            %     fixed order) — column k ALWAYS means the same identity,
            %     so "feature" and "which identity fed this column" are two
            %     names for the SAME index, the textbook coIdx case
            %     (same relationship chans/unit already have). Embodied
            %     labels on ax_W.feature are correct here, and a real
            %     co-indexed sibling (ax_W.(ftrAxisStr), base identity
            %     only, no _pcN) is set so nexOp_coIndexPairs'
            %     {'feature',<name>} entries let a results viewer resolve
            %     "feature" to real registry color automatically.
            %   - FTR IS swept: ax_W.feature and ax_W.(ftrAxisStr) (set
            %     below in the hasSwp loop) are two INDEPENDENT dimensions
            %     of the same Wfull array (confirmed from its own
            %     construction: [nFeatures x nFolds x nPerm x
            %     nSwpPerAxis...]) — NOT two names for the same index, so
            %     no coIdx pairing applies. Position 1 means "component 1"
            %     for every swept value simultaneously (Wfull is
            %     rectangular, not ragged), so only a combo-invariant ROLE
            %     label ("f1","f2",...) can be honest on ax_W.feature;
            %     the real per-(feature,combo) identity is inescapably 2-D
            %     and lives in R.featureLabels instead.
            hasBlockInfo = needsHR && exist('blockColRanges_full', 'var') && ~isempty(blockColRanges_full);
            if ~ftrIsSwept
                % Not swept — ALWAYS has a well-defined single identity per
                % column (see the case analysis above), regardless of
                % whether HR block-PCA reduction happened at all. Two
                % sub-cases for WHERE that identity comes from:
                try
                    if hasBlockInfo
                        % HR-reduced: multiple components per block, so the
                        % embodied label needs the "_pcN" suffix to stay
                        % unique — source is blockColRanges_full (the
                        % full-CTG refit's own block structure).
                        featLbl = strings(1, nFeatures);
                        srcLbl  = strings(1, nFeatures);
                        for b = 1:numel(blockColRanges_full)
                            lbl  = string(blockColRanges_full(b).label);
                            cols = blockColRanges_full(b).cols;
                            for c = 1:numel(cols)
                                if cols(c) > nFeatures, continue; end
                                srcLbl(cols(c)) = lbl;
                                if isscalar(cols)
                                    featLbl(cols(c)) = lbl;
                                else
                                    featLbl(cols(c)) = sprintf('%s_pc%d', lbl, c);
                                end
                            end
                        end
                        ax_W.feature             = featLbl(:);
                        ax_W.(char(ftrAxisStr))  = srcLbl(:);
                        R.featureLabels(:, 1)    = featLbl(:);
                    else
                        % Plain (not HR-reduced) FTR axis — e.g. domain.FTR
                        % = "f" with no reduce-mode pMap axis anywhere, so
                        % needsHR is false and blockColRanges_full never
                        % gets computed at all. nexOp_stackSTAT preserves
                        % the FTR axis (dim 2) as columns 1:1, with no PCA
                        % multiplicity — so each column's real identity is
                        % simply that axis's own tick value, directly off
                        % STAT_ctg (same convention line 747's
                        % resolveAxisDim call already uses to read ax by
                        % row), no blockColRanges_full/HR machinery
                        % involved at all.
                        srcVals = string(STAT_ctg.ax(1).(char(ftrAxisStr)));
                        if numel(srcVals) == nFeatures
                            ax_W.feature             = srcVals(:);
                            ax_W.(char(ftrAxisStr))  = srcVals(:);
                            R.featureLabels(:, 1)    = srcVals(:);
                        end
                    end
                catch e
                    fprintf('[nexAnalysis_cvPermute] feature labeling skipped: %s\n', e.message);
                end
            else
                % Swept — see the case analysis above: ax_W.feature can
                % only ever be a combo-invariant ROLE label here, with or
                % without HR info (generic "f1","f2",...). The 2-D
                % per-(feature,combo) identity in R.featureLabels still
                % needs blockColRanges_full specifically (it's sourced from
                % the HR block structure), so it's only filled when that's
                % actually available — a swept FTR axis without any HR
                % reduction isn't a configuration resolveSWPMaskHR supports
                % today anyway (its column-block masking is itself
                % HR-specific).
                ax_W.feature = ("f" + (1:nFeatures))';
                if hasBlockInfo
                    try
                        ftrAxisIdx = find(string({swpAxes.id}) == ftrAxisStr, 1);
                        for si = 1:nSwp
                            subs = swpLinToSubs(si, nSwpPerAxis);
                            regionName = string(swpAxes(ftrAxisIdx).vals(subs(ftrAxisIdx)));
                            bi = find(string({blockColRanges_full.label}) == regionName, 1);
                            if isempty(bi), continue; end
                            nComp = numel(blockColRanges_full(bi).cols);
                            for c = 1:min(nComp, nFeatures)
                                R.featureLabels(c, si) = sprintf('%s_pc%d', regionName, c);
                            end
                        end
                    catch e
                        fprintf('[nexAnalysis_cvPermute] feature labeling skipped: %s\n', e.message);
                    end
                end
            end
            ax_W.fold    = R.ax.fold;
            ax_W.perm    = R.ax.perm;
            if hasSwp
                for a = 1:numel(swpAxes)
                    ax_W.(char(swpAxes(a).id)) = swpAxes(a).vals;
                    if swpAxes(a).coField ~= ""
                        ax_W.(char(swpAxes(a).coField)) = swpAxes(a).vals;
                    end
                end
            end
            Rw = nex_initAxisPointer_v2(struct('df', Wfull, 'ax', ax_W));
            R.W     = Wfull;
            R.ax_W  = Rw.ax;
            R.ptr_W = Rw.ptr;
        else
            R.W     = [];
            R.ax_W  = struct();
            R.ptr_W = struct();
            R.featureLabels = strings(0, 0);
        end

        % ── 5f. Build result STAT row ─────────────────────────────────────────
        row = table({R.df}, {R.ax}, {R.ptr}, {R.fitSentinel}, {R.W}, {R.ax_W}, {R.ptr_W}, ...
                     'VariableNames', {'df','ax','ptr','fitSentinel','W','ax_W','ptr_W'});
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
    t0 = tic;
    RESULT = vertcat(resultRows{:});
    fprintf('[nexAnalysis_cvPermute] TIMING: vertcat(resultRows) took %.2f s\n', toc(t0));

    t0 = tic;
    if ismethod(mdlObj, 'storeResult')
        mdlObj.storeResult(resultID, RESULT);
    else
        mdlObj.RESULTS.(resultID) = RESULT;
    end
    fprintf('[nexAnalysis_cvPermute] TIMING: storeResult (incl. any viewer push) took %.2f s\n', toc(t0));

    if auditOn
        txt = sprintf('RESULT: %d rows\ncolumns: %s\n', height(RESULT), strjoin(RESULT.Properties.VariableNames, ', '));
        nexAudit_writeText(auditDir, 'RESULT_summary.txt', txt);
        fprintf('[nexAnalysis_cvPermute] audit trail complete -> %s\n', auditDir);
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
    % Extracted to nexOp_resolveAxisDim.m (DRY — also used by
    % mdlObject.fitSWPGrid's single-axis SWP resolution). Kept as a thin
    % forwarder here so every existing call site in this file is unchanged.
    dim = nexOp_resolveAxisDim(ax, ptr, axisName);
end


% ── Co-indexed sibling to ALSO pack a resolved SWP axis's vals under ─────────
% Only when vals is already a relabeled LABEL array (string/categorical/
% cellstr) — some form of pooling has already collapsed raw per-position
% identity down to a shared region label (needsHR's own block-binning, or
% regular mapID pooling upstream in nexOp_compileSTAT). At that granularity
% co-indexed siblings genuinely carry IDENTICAL per-position labels (both
% ultimately derived from the SAME chans-keyed region boundaries), so
% duplicating vals verbatim under the sibling's own field name is correct.
% Raw/unpooled numeric IDs are merely position-aligned across siblings
% (e.g. unit=42 can sit at the same position as chans=7 — not the same
% VALUE), so duplicating those would silently mislabel the sibling; "" is
% returned instead for that case, on purpose.
function coField = resolveCoIndexedSiblingIfLabeled(id, vals, ax)
    coField = "";
    if ~(isstring(vals) || iscategorical(vals) || iscellstr(vals))
        return;
    end
    coIdx = nexOp_coIndexPairs(ax);
    for p = 1:numel(coIdx)
        pair = coIdx{p};
        if ~ismember(char(id), pair), continue; end
        for m = 1:numel(pair)
            cand = string(pair{m});
            if cand == string(id), continue; end
            coField = cand;
            return;
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
    % Extracted to nexOp_swpLinToSubs.m (DRY — also used by mdlObject.
    % fitSWPGrid's multi-axis SWP grid). Kept as a thin forwarder here so
    % every existing call site in this file is unchanged.
    subs = nexOp_swpLinToSubs(si, dims);
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


% ── Slice STAT_ctg down to one SWP combo (~needsHR path only) ────────────────
% Factored out of the old inline SWP loop body unchanged — same slicing,
% same REG cropping, same terminal NaN fill — just callable once per (CTG
% combo, SWP combo) from the fold-outer precompute loop instead of inline.
function [STAT_si, sentinel] = sliceSWPCombo(STAT_ctg, si, nSwp, swpAxes, nSwpPerAxis, hasSwp, regDim)
    if hasSwp
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

    sentinel = struct();
    if ~isempty(regDim)
        [STAT_si, sentinel] = cropCanonicalREG(STAT_si, regDim);
    end

    STAT_si.df = cellfun(@zeroFillRemainingNaN, STAT_si.df, 'UniformOutput', false);
end


% ── SWP resolution for the needsHR path ───────────────────────────────────────
% A reduce-mode FTR axis (e.g. unit) sweeps by COLUMN-BLOCK — blockColRanges,
% keyed by each block's own region/bin label (matching the block labels
% resolved into swpAxes(a).vals up in section 4 for this same axis). A
% pool-mode axis (e.g. t) sweeps by ROW-GROUP, keyed by the pooled G table's
% own window-representative value for that axis. Any other SWP axis isn't
% resolvable against the reduced/pooled representation and is dropped with
% a warning rather than guessed at.
function [keepColsTrain, keepColsTest, keepRowsTrain, keepRowsTest, comboLabel] = ...
        resolveSWPMaskHR(si, nSwpPerAxis, swpAxes, hasSwp, ftrAxisStr, poolAxis, ...
                          blockColRanges, G_train, G_test)
    nColsFull     = max([blockColRanges.cols]);
    keepColsTrain = true(1, nColsFull);
    keepColsTest  = keepColsTrain;
    keepRowsTrain = true(height(G_train), 1);
    keepRowsTest  = true(height(G_test), 1);
    comboLabel    = 'all';

    if ~hasSwp, return; end

    subs       = swpLinToSubs(si, nSwpPerAxis);
    comboParts = strings(1, numel(swpAxes));
    for a = 1:numel(swpAxes)
        val = swpAxes(a).vals(subs(a));
        if swpAxes(a).id == ftrAxisStr
            bi   = find(strcmp(string({blockColRanges.label}), string(val)), 1);
            cols = false(1, nColsFull);
            if ~isempty(bi), cols(blockColRanges(bi).cols) = true; end
            keepColsTrain = keepColsTrain & cols;
            keepColsTest  = keepColsTest  & cols;
            comboParts(a) = sprintf('%s=%s(%d component(s))', swpAxes(a).id, string(val), nnz(cols));
        elseif poolAxis ~= "" && swpAxes(a).id == poolAxis
            rTr = G_train.(char(poolAxis)) == val;
            rTe = G_test.(char(poolAxis))  == val;
            keepRowsTrain = keepRowsTrain & rTr;
            keepRowsTest  = keepRowsTest  & rTe;
            comboParts(a) = sprintf('%s=%s(%d/%d row(s))', swpAxes(a).id, string(val), nnz(rTr), nnz(rTe));
        else
            warning(['[nexAnalysis_cvPermute] SWP axis "%s" is not resolvable against the ' ...
                     'reduced/pooled representation (needsHR path) — ignoring it for this combo.'], swpAxes(a).id);
            comboParts(a) = sprintf('%s=%s(unresolved)', swpAxes(a).id, string(val));
        end
    end
    comboLabel = strjoin(comboParts, ', ');
end


% ── Score a fold's held-out set directly from an already-built X/Y ───────────
% needsHR path counterpart to scoreFold — no STAT/.ptr/dn resolution needed
% (X_te/Y_te are already the exact test matrix/labels), and always a single
% aggregate score (this path requires domain.DN(1)=="None", per the SWP
% dn-exclusion rule in section 4, so there is no per-timepoint axis left to
% resolve scores over).
function score = scoreFoldDM(mdlObj, X_te, Y_te, isCont)
    Y_pred = mdlObj.predict(X_te);
    if isCont
        cc    = corrcoef(double(Y_te(:)), double(Y_pred(:)));
        score = cc(1,2)^2;
    else
        % A test point outside the TRAIN-derived quantile edges (see
        % nexOp_quantizeY — edges are fit on train Y only) comes back NaN
        % from discretize, not an error. Drop it here, on the raw numeric
        % Y_te, BEFORE the string() conversion below — string(NaN) is the
        % literal text "NaN", not MATLAB's <missing> sentinel, so filtering
        % inside balancedAccuracy itself (after stringification) wouldn't
        % catch it. Left in, it becomes its own spurious "NaN" class with
        % recall pinned at exactly 0 (Y_pred never predicts "NaN"),
        % dragging the whole balanced-accuracy mean down for no reason
        % tied to actual model performance.
        valid = ~isnan(double(Y_te(:)));
        score = balancedAccuracy(string(Y_te(valid)), Y_pred(valid));
    end
end


% ── Match raw SWP labels against one unique value (cell/string/numeric) ──────
function mask = matchesSWPValue(vals, target)
    % Extracted to nexOp_matchesSWPValue.m (DRY — also used by mdlObject.
    % fitSWPGrid's single-axis "raw" SWP narrowing). Kept as a thin
    % forwarder here so every existing call site in this file is unchanged.
    mask = nexOp_matchesSWPValue(vals, target);
end


% ── Slice all trial dfs along a given dimension at index si ──────────────────
function STAT_out = sliceSTAT(STAT_in, dim, si)
    % Extracted to nexOp_sliceSTAT.m (DRY — also used by mdlObject.
    % fitSWPGrid's single-axis SWP narrowing). Kept as a thin forwarder
    % here so every existing call site in this file is unchanged.
    STAT_out = nexOp_sliceSTAT(STAT_in, dim, si);
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

    % If Y was quantized for training (see stat2dm_supervised/
    % nexOp_quantizeY), apply the SAME bin edges to test Y before scoring —
    % Y_pred comes back decoded to bin-ID space via mdlObj.W.labelKey, so
    % comparing it against raw continuous test values would silently score
    % as ~random regardless of true model quality.
    edges = [];
    try
        edges = mdlObj.DM.K.(tVar).edges;
    catch
    end
    if ~isempty(edges)
        Y_trial = discretize(double(Y_trial), edges);
        isCont  = false;
    end

    if isCont
        Y_pred_mat = reshape(double(Y_pred_flat), nTime, nTest)';
        Y_true     = double(Y_trial(:));
        score = arrayfun(@(t) localCorrR2(Y_true, Y_pred_mat(:,t)), 1:nTime)';
    else
        Y_pred_mat = reshape(Y_pred_flat, nTime, nTest)';
        % Same out-of-train-range -> NaN filtering as scoreFoldDM (see its
        % own comment) — done once here, on the raw numeric Y_trial/whole
        % test-trial rows, before the per-timepoint arrayfun below, rather
        % than per-call inside it.
        validRows  = ~isnan(double(Y_trial(:)));
        Y_true     = string(Y_trial(validRows));
        Y_pred_mat = Y_pred_mat(validRows, :);
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


% ── Match ONLY the degenerate-scatter-matrix LDA fit failure ─────────────────
% A single- (or few-) feature SWP combo can leave the LDA eigen solver's
% within-class scatter matrix non-positive-definite ("leading minor of
% order N of B is not positive definite") — that specific, expected
% degenerate case is safe to skip (see the 4 catch sites above). Any OTHER
% error — a different Python exception, or a genuine MATLAB-side bug — is
% NOT this case and must keep propagating; e.identifier alone
% ('MATLAB:Python:PyException') is shared by every Python-raised exception
% surfaced through py.*, so it's necessary but not sufficient — the message
% text is what actually narrows it to this one failure mode. Confirmed via
% a live probe: MATLAB wraps a Python-side exception as
% matlab.exception.PyException with identifier 'MATLAB:Python:PyException'
% and a message of the form "Python Error: <PyExceptionType>: <message>".
function tf = isDegenerateScatterError(e)
    tf = strcmp(e.identifier, 'MATLAB:Python:PyException') && ...
         contains(e.message, 'LinAlgError') && ...
         contains(e.message, 'not positive definite');
end


% ── Feature-column count of a design matrix, regardless of DM shape ──────────
% "supervised" dmCfg format wraps X in a struct ({X,Y,K}, see
% stat2dm_supervised); other formats leave DM a plain numeric array. Mirrors
% nexFit_lda.m's own nFeat = size(mdlObj.DM.X, 2) resolution.
function n = nexFeatCount(DM)
    if isstruct(DM) && isfield(DM, 'X')
        n = size(DM.X, 2);
    else
        n = size(DM, 2);
    end
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
