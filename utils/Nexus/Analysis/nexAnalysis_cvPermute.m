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
% (or R²) at each time bin.  R.df shape: [nFolds × (1+nPermute) × nTime].
%
% If the STAT data has dimensions beyond D1 and FTR (e.g. a regionDropout
% axis), the analysis iterates over that outer axis automatically.
%
% Result stored in mdlObj.RESULTS.(resultID):
%   .df     [nFolds × (1+nPermute) × nTime]               (no outer axis)
%   .df     [nFolds × (1+nPermute) × nTime × nOuter]      (outer axis present)
%   .ax.fold     (1:nFolds)'
%   .ax.permute  ["real", "null_001", ...]
%   .ax.t        D1 time axis values
%   .ax.(outerAxisID)  e.g. ["NULL","STN",...] (if outer axis present)

    cvCfg = mdlObj.cfg.cvCfg.entryParams;
    nFolds   = cvCfg.nFolds;
    nPermute = cvCfg.nPermute;

    % ── 1. Compile full STAT ─────────────────────────────────────────────────
    [STAT_full, idxSel, drop] = mdlObj.compileSTAT();
    tVar = char(mdlObj.dfID_target);
    if ~ismember(tVar, STAT_full.Properties.VariableNames)
        Y_all = dtsIO_readTF(mdlObj.nexon, tVar, idxSel, 'simple');
        Y_all = Y_all(~drop);
        STAT_full.(tVar) = Y_all;
    end
    Y_all   = STAT_full.(tVar);
    nTrials = height(STAT_full);

    fitArgs = mdlObj.cfg.fitCfg.entryParams;
    dmFcn   = str2func(sprintf('stat2dm_%s', mdlObj.cfg.dmCfg.format));

    % ── 2. Detect outer iteration axis ───────────────────────────────────────
    d1Strs   = string(mdlObj.domain.D1);
    ftrStrs  = string(mdlObj.domain.FTR);
    skipAxes = [d1Strs, ftrStrs];
    ptrAxes  = string(fieldnames(STAT_full.ptr(1))');
    outerAxes = ptrAxes(~ismember(ptrAxes, skipAxes));
    if ~isempty(outerAxes)
        hasDim    = arrayfun(@(ax) ~isempty(STAT_full.ptr(1).(char(ax)).dim), outerAxes);
        outerAxes = outerAxes(hasDim);
    end
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
    if iscell(Y_all), Y_flat = [Y_all{:}]'; else, Y_flat = Y_all(:); end
    isCont = isnumeric(Y_flat);
    if isCont
        cv         = cvpartition(nTrials, 'KFold', nFolds);
        trainMasks = arrayfun(@(k) {training(cv, k)}, 1:nFolds);
    else
        trainMasks = nexStat_allocateFolds(Y_flat, nFolds);
    end

    % ── 4. Time axis — preserved in output ───────────────────────────────────
    d1   = char(mdlObj.domain.D1(1));
    d1ax = STAT_full.ax(1).(d1);
    nTime = numel(d1ax);

    % ── 5. Outer × fold loop ─────────────────────────────────────────────────
    scores = nan(nFolds, 1 + nPermute, nTime, nOuter);

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
            scores(k, 1, :, oi) = scoreFold(mdlObj, tVar, isCont, nTime);

            % Permutation null — shuffle trial-level Y in training set only
            for p = 1:nPermute
                mdlObj.TRAIN.STAT = shuffleTrialLabels(mdlObj.TRAIN.STAT, tVar);
                mdlObj.DM         = dmFcn(mdlObj);
                mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
                scores(k, 1+p, :, oi) = scoreFold(mdlObj, tVar, isCont, nTime);
            end
        end
    end

    mdlObj.STAT = STAT_full;  % restore

    % ── 6. Pack result ────────────────────────────────────────────────────────
    if ~hasOuter
        scores = scores(:,:,:,1);  % drop outer singleton
    end

    R.df         = scores;
    R.ax.fold    = (1:nFolds)';
    R.ax.permute = ["real", compose("null_%03d", 1:nPermute)];
    R.ax.t       = d1ax;
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


% ── Score one fold: time-resolved predictions ─────────────────────────────────
% Stack all trial-time rows without collapsing D1, predict per (trial,time),
% return balanced accuracy (or R²) at each time bin — shape [nTime × 1].
function score = scoreFold(mdlObj, tVar, isCont, nTime)
    STAT_test = mdlObj.TEST.STAT;

    % Custom scorer hook — bypasses all default logic when present.
    if isstruct(mdlObj.W) && isfield(mdlObj.W, 'scoreFn') && ~isempty(mdlObj.W.scoreFn)
        score = mdlObj.W.scoreFn(STAT_test, tVar);
        return;
    end

    Y_trial = STAT_test.(tVar);
    if iscell(Y_trial), Y_trial = [Y_trial{:}]'; end
    nTest = numel(STAT_test.df);

    % Custom test projection (e.g. TDR, trajectory geometry) — scalar path.
    if isstruct(mdlObj.W) && isfield(mdlObj.W, 'buildTestX') && ~isempty(mdlObj.W.buildTestX)
        X_test = mdlObj.W.buildTestX(STAT_test);
        Y_pred = mdlObj.predict(X_test);
        if isCont
            cc  = corrcoef(double(Y_trial(:)), double(Y_pred(:)));
            sc  = cc(1,2)^2;
        else
            sc = balancedAccuracy(string(Y_trial(:)), Y_pred);
        end
        score = repmat(sc, nTime, 1);  % broadcast scalar across time axis
        return;
    end

    % Default path: stack trial-time rows, preserve temporal structure.
    d1    = char(mdlObj.domain.D1(1));
    d1dim = STAT_test.ptr(1).(d1).dim;

    if d1dim == 1
        X_test = cell2mat(STAT_test.df);          % [(nTest*nTime) × nFeat]
    else
        order  = [d1dim, setdiff(1:ndims(STAT_test.df{1}), d1dim)];
        X_test = cell2mat(cellfun(@(df) permute(df, order), ...
                          STAT_test.df, 'UniformOutput', false));
    end
    X_test = reshape(X_test, nTest * nTime, []);  % ensure 2D

    Y_pred_flat = mdlObj.predict(X_test);         % [nTest*nTime × 1]

    if isCont
        Y_pred_mat = reshape(double(Y_pred_flat), nTime, nTest)';  % [nTest × nTime]
        Y_true     = double(Y_trial(:));
        score = arrayfun(@(t) localCorrR2(Y_true, Y_pred_mat(:,t)), 1:nTime)';
    else
        Y_pred_mat = reshape(Y_pred_flat, nTime, nTest)';          % [nTest × nTime]
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
