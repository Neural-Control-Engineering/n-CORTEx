function T = nexAnalysis_inspectFolds(mdlObj)
% nexAnalysis_inspectFolds  Cheap, no-fit diagnostic: reproduce
% nexAnalysis_cvPermute's CTG-combo split + fold-allocation steps ONLY —
% no SWP sweep, no fitting, no scoring — so trial counts / class balance /
% fold sizes can be inspected repeatedly without paying for a full (often
% very expensive) permutation run.
%
% Uses mdlObj.compileSTAT() directly, which reuses mdlObj.precompiledAligned
% when it's already warm (set by an earlier Compile/Fit/cvPermute press on
% this mdlObj, with no categorical/REG change since) rather than
% re-aligning from scratch — so this is safe to call over and over while
% chasing down a suspect CTG combo.
%
%   T = nexAnalysis_inspectFolds(mdlObj)
%
% Prints one block per CTG combo (trial count + per-fold train/test sizes
% and, for a categorical target, the TEST set's class breakdown — "(empty)"
% when a fold's test set has zero trials, the only way
% nexAnalysis_cvPermute's balancedAccuracy silently returns NaN). Also
% returns a table, one row per (CTG combo x fold), for programmatic
% inspection (e.g. T(T.nTest==0,:) to find every degenerate fold at once).
%
% Mirrors nexAnalysis_cvPermute.m sections 1-2 and 5a-5b exactly (same CTG
% combo enumeration, same nexStat_allocateFolds/cvpartition call) — kept as
% a deliberate small duplication rather than a shared-helper refactor of
% the production fit path, so this stays a low-risk, standalone tool.

    cvCfg  = mdlObj.cfg.cvCfg.entryParams;
    nFolds = cvCfg.nFolds;

    [STAT_full, idxSel, drop] = mdlObj.compileSTAT();
    tVar = char(mdlObj.dfID_target);
    if ~ismember(tVar, STAT_full.Properties.VariableNames)
        Y_tmp = dtsIO_readTF(mdlObj.nexon, tVar, idxSel, 'simple');
        Y_tmp = Y_tmp(~drop);
        STAT_full.(tVar) = Y_tmp;
    end

    % Same numeric coercion nexAnalysis_cvPermute.m applies — without it, a
    % continuous target read back as a string/char column looks non-numeric
    % here, isCont below comes back false, and every trial's near-unique
    % raw value becomes its own singleton "class" for nexStat_allocateFolds
    % — producing a MATLAB stratification warning and a misleading
    % diagnostic that has nothing to do with the real pipeline (which
    % already coerces this and never hits that path).
    rawTVar = STAT_full.(tVar);
    if ~isnumeric(rawTVar)
        numTry = str2double(string(rawTVar));
        if any(~isnan(numTry)), STAT_full.(tVar) = numTry; end
    end

    % needsHR mdlObjs quantize Y at the POOLED (window-level) grain, not
    % the trial-level grain checked above — G_train_p.(tVar) broadcasts
    % each trial's Y across every one of its time-windows, so a trial with
    % more surviving windows gets proportionally more weight in the
    % quantile computation than a short trial. If trial lengths/window
    % counts vary, that split can come out meaningfully more skewed than
    % the trial-level check suggests. Checked below via nexOp_stackByFTR +
    % nexOp_poolStackedDM directly on RAW (pre-PCA) X — cheap: G-column
    % pooling (trialIdx/poolAxis/tVar) never depends on X's actual values
    % or width, only nexHR_fit's PCA step does, which this skips entirely.
    needsHR = false;
    if ~isempty(mdlObj.pMap)
        pmFields = fieldnames(mdlObj.pMap);
        needsHR  = any(arrayfun(@(i) mdlObj.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
    end
    ftrAxis  = '';
    poolAxis = "";
    swpVals  = [];
    if needsHR
        ftrAxis  = char(mdlObj.domain.FTR(1));
        poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
        if poolAxis ~= ""
            % Same enumeration nexAnalysis_cvPermute.m section 4 does for
            % the pool-mode SWP axis — from TRIAL 1 ONLY (STAT_full.ax(1)),
            % once, globally, shared by every CTG combo and every fold.
            % nexOp_poolStackedDM, by contrast, bins EACH TRIAL
            % independently by its OWN position/range (see its own
            % "position-based per trial" comment) — if trial lengths/t-
            % ranges vary, a fold whose train or test trials don't happen
            % to cover the same t-range as trial 1 can come out with
            % DIFFERENT actual window IDs than this global list, silently
            % missing one or more of these values entirely. That mismatch
            % is checked below, per fold, against this same list.
            pm_id = mdlObj.pMap.(poolAxis);
            rawT1 = STAT_full.ax(1).(poolAxis);
            [~, binIDsT1] = pm_id.getBinEdges(rawT1, abs(pm_id.divsPerBin));
            swpVals = unique(binIDsT1, 'stable');
            try
                swpVals = mdlObj.applyPointerDM(poolAxis, swpVals, STAT_full.ax(1));
            catch
            end
        end
    end

    ctgCols  = string(mdlObj.domain.CTG);
    validCTG = ctgCols(ismember(ctgCols, string(STAT_full.Properties.VariableNames)));
    if ~isempty(validCTG)
        comboTbl = unique(STAT_full(:, cellstr(validCTG)), 'rows');
    else
        comboTbl = table();
    end
    nCombos = max(1, height(comboTbl));

    rows = cell(0, 11);
    for ci = 1:nCombos
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
            ctgLabel = 'all';
        end

        nTrials = height(STAT_ctg);
        if nTrials == 0
            fprintf('[nexAnalysis_inspectFolds] %s — no trials\n', ctgLabel);
            continue;
        end

        Y_ctg = STAT_ctg.(tVar);
        if iscell(Y_ctg), Y_flat = [Y_ctg{:}]'; else, Y_flat = Y_ctg(:); end
        isCont = isnumeric(Y_flat);

        if isCont
            cv         = cvpartition(nTrials, 'KFold', nFolds);
            trainMasks = arrayfun(@(k) {training(cv, k)}, 1:nFolds);
        else
            trainMasks = nexStat_allocateFolds(Y_flat, nFolds);
        end

        % Same nBinsY quantization nexAnalysis_cvPermute's needsHR branch
        % applies to Y before scoring — checked here too, PER FOLD, with
        % no PCA/reduction needed: tVar is already a per-trial column on
        % STAT_ctg, so nexOp_quantizeY can run directly on
        % Y_flat(trainMasks{k}) / Y_flat(~trainMasks{k}), exactly mirroring
        % what nexAnalysis_cvPermute does with G_train_p.(tVar)/
        % G_test_p.(tVar) (those are the same trial-level values, only
        % broadcast across pooled rows — pooling never changes which
        % distinct values exist). nexOp_quantizeY computes bin edges from
        % TRAIN only; discretize maps any TEST value outside that
        % train-derived [min,max] range to NaN — a genuinely plausible way
        % for specific folds to come back NaN with zero code bug, if a
        % fold's random split happens to put an outlier in test that
        % wasn't in train.
        nBinsY = Inf;
        try, nBinsY = mdlObj.collector.Target.nBins; catch, end

        fprintf('[nexAnalysis_inspectFolds] %s  (%d trials)\n', ctgLabel, nTrials);
        for k = 1:nFolds
            testMask = ~trainMasks{k};
            nTr = nnz(trainMasks{k});
            nTe = nnz(testMask);
            if isCont
                classStr = '(continuous)';
            else
                testY = Y_flat(testMask);
                if iscell(testY), testY = string(testY); end
                [uc, ~, ic] = unique(testY);
                counts   = accumarray(ic, 1);
                classStr = strjoin(compose("%s=%d", string(uc), counts), ', ');
                if nTe == 0, classStr = '(empty)'; end
            end
            fprintf('  fold %d/%d: train=%d test=%d  test classes: %s\n', ...
                    k, nFolds, nTr, nTe, classStr);

            nTrainClasses = NaN; nOutOfRange = NaN;
            if isCont && isfinite(nBinsY)
                [Y_train_q, edgesY] = nexOp_quantizeY(Y_flat(trainMasks{k}), nBinsY);
                nTrainClasses = numel(unique(Y_train_q(~isnan(Y_train_q))));
                if ~isempty(edgesY)
                    testVals    = Y_flat(testMask);
                    nOutOfRange = nnz(testVals < edgesY(1) | testVals > edgesY(end));
                    fprintf(['    quantize (nBins=%d): edges=%s  train classes=%d/%d  ' ...
                             'test points out of train range (-> NaN)=%d/%d\n'], ...
                            nBinsY, mat2str(edgesY, 4), nTrainClasses, nBinsY, nOutOfRange, nTe);
                else
                    fprintf('    quantize (nBins=%d): pass-through (not continuous enough / nBins>=nUnique)\n', nBinsY);
                end
            end

            % Pooled/window-level re-check (needsHR only) — the ACTUAL
            % grain nexAnalysis_cvPermute quantizes at for this mdlObj.
            nTrainClassesPooled = NaN; nOutOfRangePooled = NaN;
            nMissingTrainWin = NaN; nMissingTestWin = NaN;
            if needsHR && isCont && isfinite(nBinsY) && poolAxis ~= ""
                try
                    STAT_train = STAT_ctg(trainMasks{k} == 1, :);
                    STAT_test  = STAT_ctg(trainMasks{k} == 0, :);
                    [X_raw_tr, G_raw_tr] = nexOp_stackByFTR(STAT_train, ftrAxis);
                    [X_raw_te, G_raw_te] = nexOp_stackByFTR(STAT_test, ftrAxis);
                    [~, G_train_p] = nexOp_poolStackedDM(X_raw_tr, G_raw_tr, mdlObj.pMap, poolAxis);
                    [~, G_test_p]  = nexOp_poolStackedDM(X_raw_te, G_raw_te, mdlObj.pMap, poolAxis);

                    % Missing-window check: for EACH globally-enumerated
                    % SWP window value (swpVals, from trial 1 — see above),
                    % does THIS fold's train/test set actually contain any
                    % pooled row at that window ID? A window with zero test
                    % rows means resolveSWPMaskHR's keepRowsTest comes back
                    % all-false for every SWP combo naming that window —
                    % Y_te ends up genuinely EMPTY, and
                    % balancedAccuracy(string([]), []) -> mean([]) -> a
                    % real, literal NaN (not the recall=0 "spurious class"
                    % case) — for every SWP combo sharing that window,
                    % across every region. If that happens for MOST/ALL of
                    % this fold's windows, the whole fold goes NaN
                    % everywhere, matching what you saw.
                    if ~isempty(swpVals)
                        trainWin = G_train_p.(poolAxis);
                        testWin  = G_test_p.(poolAxis);
                        hasTrain = ismember(swpVals, trainWin);
                        hasTest  = ismember(swpVals, testWin);
                        nMissingTrainWin = nnz(~hasTrain);
                        nMissingTestWin  = nnz(~hasTest);
                        missingSuffix = '';
                        if nMissingTestWin > 0
                            missingTestWinList = strjoin(compose("%.4g", swpVals(~hasTest)), ', ');
                            missingSuffix = sprintf('  (missing: %s)', missingTestWinList);
                        end
                        fprintf(['    [SWP window coverage] %d window(s) total — missing from ' ...
                                 'TRAIN=%d, missing from TEST=%d%s\n'], ...
                                numel(swpVals), nMissingTrainWin, nMissingTestWin, missingSuffix);
                    end

                    Yp_train = G_train_p.(tVar); if iscell(Yp_train), Yp_train = [Yp_train{:}]'; end
                    Yp_test  = G_test_p.(tVar);  if iscell(Yp_test),  Yp_test  = [Yp_test{:}]';  end
                    [Yp_train_q, edgesY_p] = nexOp_quantizeY(Yp_train, nBinsY);
                    nTrainClassesPooled = numel(unique(Yp_train_q(~isnan(Yp_train_q))));
                    if ~isempty(edgesY_p)
                        nOutOfRangePooled = nnz(Yp_test < edgesY_p(1) | Yp_test > edgesY_p(end));
                        fprintf(['    [pooled/window-level] edges=%s  train classes=%d/%d  ' ...
                                 'test WINDOWS out of range (-> NaN)=%d/%d  (%d train windows)\n'], ...
                                mat2str(edgesY_p, 4), nTrainClassesPooled, nBinsY, ...
                                nOutOfRangePooled, numel(Yp_test), numel(Yp_train));
                    end
                catch e
                    fprintf('    [pooled/window-level] check failed: %s\n', e.message);
                end
            end

            rows(end+1, :) = {ctgLabel, k, nTr, nTe, classStr, nTrainClasses, nOutOfRange, ...
                               nTrainClassesPooled, nOutOfRangePooled, ...
                               nMissingTrainWin, nMissingTestWin}; %#ok<AGROW>
        end
    end
    T = cell2table(rows, 'VariableNames', ...
        {'ctgLabel', 'fold', 'nTrain', 'nTest', 'testClasses', 'nTrainClasses', 'nTestOutOfRange', ...
         'nTrainClassesPooled', 'nTestOutOfRangePooled', 'nMissingTrainWindows', 'nMissingTestWindows'});
end
