function DM = stat2dm_dpca(mdlObj)
% Build the dPCA design matrix from compiled SSM latent trajectories.
%
% Reads STAT.df (N_latents × T per trial, already trimmed + D1-first by
% compileSTAT) and condition variable values stored in mdlObj.UserData.
%
% Outputs
%   DM.X_avg          (N_lat × S1 [× S2 ...] × T)          condition-averaged
%   DM.X_single       (N_lat × S1 [× S2 ...] × T × maxN)   NaN-padded single trial
%   DM.combinedParams cell — all 2^K condition subsets + {} for time-only
%   DM.margNames      cell of human-readable marginalization labels
%   DM.condLabels     {K×1} cell of string arrays (unique bin labels per condVar)
%   DM.condVars       string array of condition variable names
%   DM.condSizes      (1 × K) integer — number of unique levels per condVar

    STAT     = mdlObj.TRAIN.STAT;
    nBins    = mdlObj.cfg.fitCfg.entryParams.nBins;
    condVars = string(mdlObj.collector.CondVars.Y);
    condVars = condVars(condVars ~= "");
    nCV      = numel(condVars);
    if nCV == 0
        error('stat2dm_dpca: no condition variables selected in collector.CondVars.Y');
    end

    %% Stack X: (N_lat × T × N_trials) from STAT.df cells (T × N_lat each)
    N_trials = height(STAT);
    T_ref    = size(STAT.df{1}, 1);
    N_lat    = size(STAT.df{1}, 2);
    X_raw    = zeros(N_lat, T_ref, N_trials);
    for r = 1:N_trials
        df_r = STAT.df{r};
        if size(df_r, 1) == T_ref
            X_raw(:, :, r) = df_r';
        end
    end

    %% Resolve condition variable values — STAT columns first, DTS fallback
    % idxSel_train: DTS row indices for the training set rows in STAT.
    % Stored by mdlObj_dPCA.compileSTAT into mdlObj.UserData.idxSel_train.
    condIdx    = zeros(N_trials, nCV, 'int32');
    condLabels = cell(nCV, 1);

    for ci = 1:nCV
        col = char(condVars(ci));

        % Try STAT group column first (e.g. sessionLabel_phase)
        if ismember(col, STAT.Properties.VariableNames)
            raw = STAT.(col);
        elseif isfield(mdlObj.UserData, 'idxSel_train') ...
                && ~isempty(mdlObj.UserData.idxSel_train)
            % DTS manifest / HDF5 fallback
            idxTrain = mdlObj.UserData.idxSel_train;
            DTS      = mdlObj.nexon.console.BASE.DTS;
            col_dts  = strrep(col, 'h5_', '');  % strip prefix used in bus
            try
                raw = dtsIO_readTFH5(DTS, col_dts, idxTrain, 'simple');
                if iscell(raw)
                    raw = cellfun(@(x) double(x(1)), raw(:), 'UniformOutput', true);
                end
            catch
                warning('stat2dm_dpca: cannot read condVar "%s" — skipping', col);
                condIdx(:, ci)  = ones(N_trials, 1, 'int32');
                condLabels{ci}  = string(col) + "_unknown";
                continue;
            end
        else
            warning('stat2dm_dpca: condVar "%s" not found in STAT or DTS — skipping', col);
            condIdx(:, ci)  = ones(N_trials, 1, 'int32');
            condLabels{ci}  = string(col) + "_unknown";
            continue;
        end

        % Recover numeric if stored as string (nexOp_compileSTAT coerces types)
        if ~isnumeric(raw)
            numTry = str2double(string(raw));
            if all(~isnan(numTry)), raw = numTry; end
        end

        % Normalise to (N_trials × 1) — for matrix inputs take first column only
        if ~isvector(raw)
            raw = raw(:, 1);
        else
            raw = raw(:);
        end

        % Quantile-bin continuous columns with more than nBins unique values
        if isnumeric(raw) && numel(unique(raw(~isnan(raw)))) > nBins
            vals  = raw(~isnan(raw));
            edges = quantile(vals, linspace(0, 1, nBins + 1));
            edges(end) = edges(end) + abs(edges(end)) * 1e-10 + 1e-10;
            binIdx = discretize(raw, edges);
            labels = strings(nBins, 1);
            for b = 1:nBins
                m = binIdx == b;
                if any(m)
                    labels(b) = sprintf('%s_q%d(%.3g)', col, b, mean(raw(m), 'omitnan'));
                end
            end
            condIdx(:, ci)  = int32(binIdx);
            condLabels{ci}  = labels;
        else
            [~, ~, idx] = unique(string(raw), 'stable');
            condIdx(:, ci) = int32(idx);
            condLabels{ci} = unique(string(raw), 'stable');
        end
    end

    condSizes = arrayfun(@(ci) numel(condLabels{ci}), 1:nCV);

    %% Build X_avg (N_lat × S1 × S2 × ... × T) and X_single (... × maxN)
    avgShape    = [N_lat, condSizes, T_ref];
    X_avg       = NaN(avgShape);

    [groups, groupIDs] = findgroups(array2table(condIdx, ...
        'VariableNames', cellstr(condVars)));
    maxN        = max(accumarray(groups, 1));
    singleShape = [N_lat, condSizes, T_ref, maxN];
    X_single    = NaN(singleShape);

    nGroups = height(groupIDs);
    for g = 1:nGroups
        mask_g  = groups == g;
        X_g     = X_raw(:, :, mask_g);               % (N_lat × T × n_g)
        idx_g   = table2array(groupIDs(g, :));        % [s1, s2, ...]
        n_g     = sum(mask_g);

        % Index into N_lat+cond+T dimensions: {:, s1, s2, ..., :}
        avgSub         = [{':'}, num2cell(idx_g), {':'}];
        X_avg(avgSub{:}) = mean(X_g, 3);

        singleSub              = [{':'}, num2cell(idx_g), {':', 1:n_g}];
        X_single(singleSub{:}) = X_g;
    end

    %% Build combinedParams (grouped): each entry pairs a condition subset with
    % its time-interaction counterpart so dPCA captures all flavors of
    % condition-dependent variance in one set of axes.
    %
    % timeIdx = nCV+1 because X_avg is (N_lat × S1 × ... × SK × T) and
    % dPCA treats the last dimension as explicit parameter nCV+1.
    %
    % Example for nCV=2 (phase, threshold):
    %   {1,[1 3]}, {2,[2 3]}, {[1 2],[1 2 3]}, {3}
    timeIdx = nCV + 1;
    combinedParams = {};
    margNames      = {};
    for k = 1:nCV
        combos = nchoosek(1:nCV, k);
        for j = 1:size(combos, 1)
            cond_sub  = combos(j, :);
            with_time = [cond_sub, timeIdx];
            combinedParams{end+1} = {cond_sub, with_time}; %#ok<AGROW>
            margNames{end+1}      = char(strjoin(condVars(cond_sub), ' × ')); %#ok<AGROW>
        end
    end
    combinedParams{end+1} = {timeIdx};   % condition-invariant time
    margNames{end+1}      = 'time';

    %% numOfTrials: (N_lat × S1 × ... × SK) — required shape for dpca_optimizeLambda.
    % "One dimension fewer than X" means no time dim but neuron dim present.
    % Count non-NaN trials per condition cell from the last dim of X_single,
    % then replicate across the neuron dimension.
    trialDim      = ndims(X_single);                           % last dim = maxN
    sliceIdx      = [{1}, repmat({':'}, 1, nCV), {1}, {':'}];  % (1 × S1×...×SK × 1 × maxN)
    trialCounts   = squeeze(sum(~isnan(X_single(sliceIdx{:})), trialDim)); % (S1 × ... × SK)
    numOfTrials   = repmat(reshape(trialCounts, [1, condSizes]), [N_lat, ones(1, nCV)]); % (N_lat × S1 × ... × SK)

    DM.X_avg         = X_avg;
    DM.X_single      = X_single;
    DM.numOfTrials   = numOfTrials;
    DM.combinedParams = combinedParams;
    DM.margNames     = margNames;
    DM.condLabels    = condLabels;
    DM.condVars      = condVars;
    DM.condSizes     = condSizes;

    fprintf('[stat2dm_dpca] X_avg: [%s]  |  %d marginalizations  |  %d trials\n', ...
        num2str(size(X_avg)), numel(combinedParams), N_trials);
end
