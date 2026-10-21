function Tresid = build_residualTable(T)
% build_residualTable  Per-(subject,chans,band) regression of each
% channel's band power onto a LEAVE-ONE-CHANNEL-OUT shared-signal
% estimate, returning the RESIDUAL in the same shape as T.
%
% Why leave-one-out, not the plain cross-channel mean (build_
% globalSignalTable's own Tglobal, which is fine for ITS purpose --
% testing whether the shared signal itself predicts condition -- but
% wrong to reuse here): with ~18 channels, each one is ~5-6% of a plain
% average, so regressing a channel against an average that includes
% itself partly regresses it against itself -- any genuine LOCAL signal
% that channel has leaks into the "shared" estimate and gets subtracted
% back out along with the real confound. That's a known failure mode of
% naive global-signal regression with a modest channel count (same issue
% in EEG common-average referencing and the fMRI global-signal-regression
% literature). Excluding the channel itself from its own regressor avoids
% it, at negligible cost to the regressor's own stability (17-18 channels
% is still plenty).
%
%   T      : output of build_bandPowerRegionTable (needs 'trial')
%   Tresid : same columns as T, bandPower replaced by the leave-one-
%            channel-out residual. Rows in a (subject,chans,band) group
%            with <5 points are left NaN, not fabricated.

    t0 = tic;
    if ~ismember('chans', T.Properties.VariableNames)
        error('build_residualTable:noChans', 'T has no ''chans'' column.');
    end

    % Leave-one-channel-out global regressor per row: group by everything
    % EXCEPT chans/bandPower (subject,condition,trial,band,t,...) -- i.e.
    % exactly the set of rows that differ only in which channel they are
    % -- then for row i in group g, looGlobal_i = (sum of the group's
    % bandPower, minus this row's own) / (count - 1).
    groupVars = setdiff(T.Properties.VariableNames, {'chans', 'bandPower'}, 'stable');
    g = findgroups(T(:, groupVars));
    groupSum   = accumarray(g, T.bandPower);
    groupCount = accumarray(g, 1);
    nChansInGroup = groupCount(g);
    if any(nChansInGroup < 3)
        error('build_residualTable:tooFewChans', ...
            ['Some (%s) group has <3 channels -- leave-one-out mean is ' ...
             'unstable with that few.'], strjoin(groupVars, ','));
    end
    fprintf('[build_residualTable] leave-one-out global signal: %d channel(s) per group\n', ...
        mode(nChansInGroup) + 1);
    T.looGlobal = (groupSum(g) - T.bandPower) ./ (nChansInGroup - 1);

    % Per-(subject,chans,band) OLS of bandPower onto its own leave-one-out
    % regressor, pooled across trial and t for a stable estimate (same
    % rationale as the earlier version -- one loading per channel-band,
    % not re-estimated per time window).
    subjList  = unique(T.subject);
    chansList = categories(T.chans);
    bandList  = categories(T.band);
    nGroups   = numel(subjList) * numel(chansList) * numel(bandList);
    fprintf('[build_residualTable] regressing %d (subject x chans x band) group(s)...\n', nGroups);

    resid = nan(height(T), 1);
    nSkipped = 0;
    for si = 1:numel(subjList)
        for ci = 1:numel(chansList)
            for bi = 1:numel(bandList)
                mask = T.subject == subjList(si) & T.chans == chansList{ci} & T.band == bandList{bi};
                n = nnz(mask);
                if n < 5
                    nSkipped = nSkipped + 1;
                    continue;
                end
                x = T.looGlobal(mask);
                y = T.bandPower(mask);
                X = [ones(n, 1), x];
                beta = X \ y;
                resid(mask) = y - X * beta;
            end
        end
    end
    if nSkipped > 0
        fprintf('[build_residualTable] %d/%d group(s) skipped (too few rows, <5) -- left NaN\n', nSkipped, nGroups);
    end

    Tresid = T(:, setdiff(T.Properties.VariableNames, {'looGlobal', 'bandPower'}, 'stable'));
    Tresid.bandPower = resid;
    fprintf('[build_residualTable] done: %d rows, %d NaN -- %.2f s\n', ...
        height(Tresid), nnz(isnan(Tresid.bandPower)), toc(t0));
end
