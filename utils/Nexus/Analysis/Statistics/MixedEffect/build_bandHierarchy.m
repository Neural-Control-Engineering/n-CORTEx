function results = build_bandHierarchy(T)
% build_bandHierarchy  Per-grid-cell stepwise mixed-model hierarchy + flat
% FDR correction across the whole grid. Needs Statistics and Machine
% Learning Toolbox (fitlme/compare).
%
% Grid dimensions are every column of T except subject/condition/
% bandPower — so {band} alone, or {band, chans, t} if
% build_bandPowerRegionTable pulled those in (its default). Each cell is
% one unique combination of those columns' values — with chans/t as grid
% dimensions, each cell holds exactly one row per trial (no
% non-independence left to account for), which is why there's no
% trial-level random effect here despite T itself having one row per
% (trial, chans, t, band).
%
%   T : output of build_bandPowerRegionTable (subject, condition,
%       bandPower, band, + whatever gridCols it carried)
%
%   results : table, one row per grid cell, with each step's LRT p-value
%             and the final condition-effect estimate + p-value (both
%             raw and FDR-corrected across every row).

    tAll = tic;
    % 'trial' (build_bandPowerRegionTable's trialNumber identifier) is an
    % always-present per-row id, not a grid dimension to loop fitlme over.
    % 'side'/'cci' (sessionLabel_phase-derived) are meant to be FILTERED
    % on by the caller beforehand (stratified pre-/post-CCI, left/right
    % analyses -- keeps those from ever sharing one model fit or one
    % multiple-comparisons pool), not looped here either -- all five
    % excluded the same way subject/condition/bandPower are.
    gridVars = setdiff(T.Properties.VariableNames, ...
        {'subject','condition','trial','side','cci','bandPower'}, 'stable');
    if isempty(gridVars)
        error('build_bandHierarchy:noGridVars', 'T has no grid columns beyond subject/condition/bandPower.');
    end
    fprintf('[build_bandHierarchy] grid dimensions: %s\n', strjoin(string(gridVars), ' x '));

    gridLevels = cell(1, numel(gridVars));
    for gi = 1:numel(gridVars)
        gridLevels{gi} = categories(T.(gridVars{gi}));
    end
    gridSizes = cellfun(@numel, gridLevels);
    nCells    = prod(gridSizes);
    fprintf('[build_bandHierarchy] %s = %d cell(s)\n', ...
        strjoin(string(gridSizes), ' x '), nCells);

    varTypes = [repmat({'string'}, 1, numel(gridVars)), {'double','double','double','double','double'}];
    varNames = [gridVars, {'p_conditionFixed','p_conditionRandomSlope', ...
                            'conditionEffect','conditionEffect_p','conditionEffect_p_corrected'}];
    results = table('Size', [nCells, numel(varNames)], 'VariableTypes', varTypes, 'VariableNames', varNames);

    for r = 1:nCells
        tCell = tic;
        % ind2sub requires >=2 size elements -- errors outright for the
        % single-grid-dimension case (band alone, no chans/t). Same
        % mixed-radix decomposition ind2sub uses internally (first
        % dimension fastest-varying), written out to handle any number of
        % dimensions including 1.
        subs = zeros(1, numel(gridVars));
        rem  = r - 1;
        for gi = 1:numel(gridVars)
            subs(gi) = mod(rem, gridSizes(gi)) + 1;
            rem = floor(rem / gridSizes(gi));
        end
        mask = true(height(T), 1);
        cellDesc = strings(1, numel(gridVars));
        for gi = 1:numel(gridVars)
            lvl = gridLevels{gi}{subs(gi)};
            mask = mask & (T.(gridVars{gi}) == lvl);
            results.(gridVars{gi})(r) = lvl;
            cellDesc(gi) = sprintf('%s=%s', gridVars{gi}, lvl);
        end
        Tc    = T(mask, :);
        nSubj = numel(unique(Tc.subject));
        fprintf('[build_bandHierarchy] cell %d/%d: %s (%d rows, %d subjects)... ', ...
            r, nCells, strjoin(cellDesc, ', '), height(Tc), nSubj);
        if height(Tc) < 10 || nSubj < 2
            fprintf('skipped (too little data)\n');
            results.p_conditionFixed(r)       = NaN;
            results.p_conditionRandomSlope(r) = NaN;
            results.conditionEffect(r)        = NaN;
            results.conditionEffect_p(r)      = NaN;
            continue;
        end
        Tc.condition = categorical(Tc.condition);
        % Hard, cheap guard BEFORE the expensive fitlme calls: a
        % continuous/near-continuous condition (e.g. quantizeY not
        % actually applied upstream) turns into a huge-level factor here,
        % and fitlme building/optimizing that design matrix can run for
        % many minutes in a tight loop Ctrl+C can't interrupt -- better to
        % fail loudly in milliseconds than hang silently.
        nCondLevels = numel(categories(Tc.condition));
        if nCondLevels > 30
            error('build_bandHierarchy:tooManyConditionLevels', ...
                ['condition has %d levels for cell %s -- expected a small discrete ' ...
                 'factor (2, typically). This almost certainly means ' ...
                 'build_bandPowerRegionTable''s quantizeY step was a pass-through ' ...
                 '(mdlObj.collector.Target.nBins not set to what the LDA actually ' ...
                 'used) -- condition is still continuous. Check that before re-running.'], ...
                nCondLevels, strjoin(cellDesc, ', '));
        end

        m0 = fitlme(Tc, 'bandPower ~ 1 + (1|subject)');
        m1 = fitlme(Tc, 'bandPower ~ 1 + condition + (1|subject)');
        c1 = compare(m0, m1);
        m2 = fitlme(Tc, 'bandPower ~ 1 + condition + (1 + condition|subject)');
        c2 = compare(m1, m2);
        % NOTE: compare()'s LRT on an added random-effect term sits on a
        % variance boundary (>=0) -- fitlme's own compare() already
        % applies the correct reference distribution for this. Don't
        % bypass it with a hand-rolled chi-square.

        results.p_conditionFixed(r)       = c1.pValue(2);
        results.p_conditionRandomSlope(r) = c2.pValue(2);
        coefTbl = m1.Coefficients;
        condRow = contains(coefTbl.Name, 'condition');
        results.conditionEffect(r)   = coefTbl.Estimate(condRow);
        results.conditionEffect_p(r) = coefTbl.pValue(condRow);
        fprintf('p_fixed=%.4f, p_randomSlope=%.4f -- %.2f s\n', ...
            results.p_conditionFixed(r), results.p_conditionRandomSlope(r), toc(tCell));
    end

    % Flat Benjamini-Hochberg FDR across every grid cell with a real
    % p-value -- the whole grid is the multiple-comparisons surface now.
    fprintf('[build_bandHierarchy] applying FDR correction across %d fitted cell(s)...\n', ...
        nnz(~isnan(results.conditionEffect_p)));
    valid = ~isnan(results.conditionEffect_p);
    pv    = results.conditionEffect_p(valid);
    m     = numel(pv);
    [~, order] = sort(pv);
    adj = nan(m, 1);
    for k = 1:m
        adj(order(k)) = pv(order(k)) * m / k;
    end
    for k = m-1:-1:1
        adj(order(k)) = min(adj(order(k)), adj(order(k+1)));
    end
    results.conditionEffect_p_corrected = nan(nCells, 1);
    results.conditionEffect_p_corrected(valid) = min(adj, 1);
    fprintf('[build_bandHierarchy] done: %d/%d cells fitted -- total %.2f s\n', ...
        m, nCells, toc(tAll));
end
