function nexAnalysis_cvPermute(mdlObj, cvCfg)
% N-fold cross-validation with permutation null distribution.
%
%   nexAnalysis_cvPermute(mdlObj, cvCfg)
%
%   mdlObj : mdlObject subclass (linear, lda, logistic).
%            mdlObj.Parent must be the nexObj_categorical that drives
%            compileSTAT — wired at construction or by mdlObj_fromState.
%   cvCfg  : struct with fields:
%              nFolds      — number of CV folds
%              nPermute    — number of permutation iterations
%              resultID    — key written to mdlObj.RESULTS
%              resultsPath — (optional) .mat path to save result
%
% Folds are split at trial level to prevent data leakage across time.
% Permutations shuffle trial-level Y (preserving within-trial temporal
% structure) to build a null distribution per fold.
%
% If the STAT data has dimensions beyond D1 and FTR (e.g. a regionDropout
% axis), the analysis iterates over that outer axis automatically.
%
% Result stored in mdlObj.RESULTS.(resultID):
%   .df                      [nFolds × (1+nPermute)]                (no outer axis)
%   .df                      [nFolds × (1+nPermute) × nOuter]       (outer axis present)
%   .ax.fold                 (1:nFolds)'
%   .ax.permute              ["real", "null_001", ...]
%   .ax.(outerAxisID)        e.g. ["NULL","STN",...] (if outer axis present)

    nFolds   = cvCfg.nFolds;
    nPermute = cvCfg.nPermute;
    resultID = cvCfg.resultID;

    % ── 1. Compile full STAT ─────────────────────────────────────────────────
    mdlObj.compileSTAT();
    STAT_full = mdlObj.STAT;
    nTrials   = height(STAT_full);
    tVar      = char(mdlObj.dfID_target);
    fitArgs   = mdlObj.cfg.fitCfg.entryParams;
    dmFcn     = str2func(sprintf('stat2dm_%s', mdlObj.cfg.dmCfg.format));

    % ── 2. Detect outer iteration axis (axes beyond D1 and FTR in ptr) ───────
    d1Strs   = string(mdlObj.domain.D1);
    ftrStrs  = string(mdlObj.domain.FTR);
    skipAxes = [d1Strs, ftrStrs];
    ptrAxes  = string(fieldnames(STAT_full.ptr(1))');
    outerAxes = ptrAxes(~ismember(ptrAxes, skipAxes));

    hasOuter = ~isempty(outerAxes);
    if hasOuter
        outerID   = char(outerAxes(1));
        outerVals = STAT_full.ax(1).(outerID);
        nOuter    = numel(outerVals);
        outerDim  = STAT_full.ptr(1).(outerID).dim;
        fprintf('[nexAnalysis_cvPermute] outer axis: %s (%d values)\n', outerID, nOuter);
    else
        nOuter = 1;
    end

    % ── 3. Y type and trial-level fold allocation ────────────────────────────
    Y_all  = STAT_full.(tVar);
    if iscell(Y_all), Y_flat = [Y_all{:}]'; else, Y_flat = Y_all(:); end
    isCont = isnumeric(Y_flat);

    if isCont
        cv         = cvpartition(nTrials, 'KFold', nFolds);
        trainMasks = arrayfun(@(k) {training(cv, k)}, 1:nFolds);
    else
        trainMasks = nexStat_allocateFolds(Y_flat, nFolds);
    end

    % ── 4. Outer × fold loop ─────────────────────────────────────────────────
    scores = nan(nFolds, 1 + nPermute, nOuter);

    for oi = 1:nOuter
        if hasOuter
            fprintf('[nexAnalysis_cvPermute]   %s %d/%d (%s)\n', ...
                    outerID, oi, nOuter, outerVals(oi));
            STAT_oi = sliceSTAT(STAT_full, outerDim, oi);
        else
            STAT_oi = STAT_full;
        end

        for k = 1:nFolds
            mdlObj.trainMask = logical(trainMasks{k});
            mdlObj.STAT      = STAT_oi;

            % Real fold
            mdlObj.getDesignMatrix();
            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
            scores(k, 1, oi) = scoreFold(mdlObj, tVar, isCont);

            % Permutation null folds — shuffle trial-level Y in training set only
            for p = 1:nPermute
                mdlObj.TRAIN.STAT = shuffleTrialLabels(mdlObj.TRAIN.STAT, tVar);
                mdlObj.DM         = dmFcn(mdlObj);
                mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                scores(k, 1+p, oi) = scoreFold(mdlObj, tVar, isCont);
            end
        end
    end

    mdlObj.STAT = STAT_full;  % restore

    % ── 5. Pack result ────────────────────────────────────────────────────────
    % Squeeze outer dim if no outer axis so shape stays [nFolds × (1+nPermute)]
    if ~hasOuter
        scores = scores(:,:,1);
    end

    R.df         = scores;
    R.ax.fold    = (1:nFolds)';
    R.ax.permute = ["real", compose("null_%03d", 1:nPermute)];
    if hasOuter
        R.ax.(outerID) = outerVals;
    end

    if ismethod(mdlObj, 'storeResult')
        mdlObj.storeResult(resultID, R);
    else
        mdlObj.RESULTS.(resultID) = R;
    end

    if isfield(cvCfg, 'resultsPath') && ~isempty(cvCfg.resultsPath)
        [pDir,~,~] = fileparts(cvCfg.resultsPath);
        if ~isfolder(pDir), mkdir(pDir); end
        save(cvCfg.resultsPath, 'R');
        fprintf('[nexAnalysis_cvPermute] saved → %s\n', cvCfg.resultsPath);
    end
    fprintf('[nexAnalysis_cvPermute] done — %s\n', resultID);
end


% ── Slice all trial dfs along a given dimension at index oi ──────────────────
function STAT_out = sliceSTAT(STAT_in, dim, oi)
    STAT_out    = STAT_in;
    STAT_out.df = cellfun(@(df) sliceDim(df, dim, oi), STAT_in.df, 'UniformOutput', false);
end

function X = sliceDim(A, dim, idx)
    S      = repmat({':'}, 1, ndims(A));
    S{dim} = idx;
    X      = squeeze(A(S{:}));
end


% ── Stack TEST.STAT, predict, return fold score ───────────────────────────────
function score = scoreFold(mdlObj, tVar, isCont)
    STAT_test = mdlObj.TEST.STAT;
    X_test    = nexOp_stackSamples(STAT_test, "stack", mdlObj.domain.D1);

    Y_trial = STAT_test.(tVar);
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    nRowsTest = cellfun(@(df) size(df,1), STAT_test.df);

    if isCont
        Y_test = double(repelem(double(Y_trial(:)), nRowsTest));
        Y_pred = mdlObj.predict(X_test);
        cc     = corrcoef(Y_test(:), Y_pred(:));
        score  = cc(1,2)^2;
    else
        Y_test    = repelem(string(Y_trial(:)), nRowsTest);
        np        = py.importlib.import_module('numpy');
        Y_py      = mdlObj.model.predict(np.array(double(X_test)));
        Y_pred    = string(cellfun(@char, cell(Y_py), 'UniformOutput', false));
        score     = balancedAccuracy(Y_test, Y_pred);
    end
end


% ── Permute trial-level Y labels within STAT (copy, not in-place) ────────────
function STAT_out = shuffleTrialLabels(STAT_in, tVar)
    STAT_out         = STAT_in;
    nTrials          = height(STAT_in);
    STAT_out.(tVar)  = STAT_in.(tVar)(randperm(nTrials));
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
