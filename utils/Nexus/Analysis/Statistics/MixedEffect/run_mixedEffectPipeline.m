function results = run_mixedEffectPipeline(mdlObj, makePlots, forceRecompile)
% run_mixedEffectPipeline  One-call wrapper for the full stratified
% band-power mixed-effects screen: builds the long-format table, splits
% it into the four (side x CCI-status) strata, runs the band x chans x t
% hierarchy independently in each, and (optionally) plots each one.
%
% Pre-CCI and post-CCI NEVER share a model fit or a multiple-comparisons
% pool here, and neither do left/right -- each stratum gets its own
% build_bandHierarchy call, so injury-induced hyperalgesia can't leak
% into a baseline-sensory-coding question or vice versa (Nexus WIP.md's
% MixedEffect notes).
%
%   mdlObj    : an mdlObj_lda (or any mdlObj) with dfID_source,
%               dfID_target, and pMap already configured as for its own
%               LDA fit. mdlObj.STAT must carry a sessionLabel_phase
%               column (e.g. "L-hind-paw-CCI") -- that's what gets parsed
%               into the side/cci strata.
%   makePlots : optional, default true. Calls plot_bandHierarchyGrid
%               (conditionEffect_p_corrected, default 0.05 threshold) for
%               each of the 4 strata, with the stratum name set as the
%               figure window title. mdlObj.nexon is passed through so the
%               chans axis is ordered deep -> shallow (nexObj_bar's own
%               convention, via nexOp_regionDepthOrder) rather than plain
%               encounter order. All 4 strata are plotted on the SAME
%               color-axis limits (compute_bandHierarchyClim, computed
%               once across every stratum actually run) so a "bright"
%               cell means the same thing in every figure.
%   forceRecompile : optional, default false. Forwarded to
%               build_bandPowerRegionTable -- mdlObj.STAT only gets
%               rebuilt by mdlObj.compileSTAT() itself, never by
%               precompileSTAT()/"Compile" alone (that only refreshes the
%               lower-level TF-alignment cache, mdlObj.precompiledAligned).
%               Pass true any time you've changed the averaging
%               selection/subject set since mdlObj.STAT was last
%               populated, so this pipeline doesn't silently keep using a
%               stale STAT.
%
%   results : struct with fields:
%               T                      -- the full (unstratified) table
%               preCCI_L / preCCI_R / postCCI_L / postCCI_R
%                                      -- build_bandHierarchy output per
%                                         stratum (missing/empty if that
%                                         stratum had 0 rows)
%               counts                 -- per-stratum, per-subject
%                                         distinct-trial-count table (the
%                                         sanity check worth eyeballing
%                                         before trusting any one stratum)

    if nargin < 2 || isempty(makePlots), makePlots = true; end
    if nargin < 3 || isempty(forceRecompile), forceRecompile = false; end

    fprintf('===== run_mixedEffectPipeline: building band-power table =====\n');
    T = build_bandPowerRegionTable(mdlObj, forceRecompile);
    strataT = stratifyMixedEffectT(T);

    names   = fieldnames(strataT);
    results = struct('T', T);
    counts  = struct();
    for i = 1:numel(names)
        name = names{i};
        Ts = strataT.(name);

        if height(Ts) == 0
            fprintf('\n----- %s: 0 rows -- skipped -----\n', name);
            continue;
        end

        % Per-subject DISTINCT-trial count (not raw row count, which is
        % inflated by nBands x nChans x nT per trial) -- the sanity check
        % worth eyeballing before trusting any one stratum, since with
        % only a handful of subjects total, one subject missing entirely
        % from a stratum thins its random-effects estimate a lot.
        [uSubj, ~, subjIdx] = unique(Ts.subject);
        uSubjTrial = unique([double(subjIdx), Ts.trial], 'rows');
        trialCountsPerSubj = accumarray(uSubjTrial(:,1), 1, [numel(uSubj), 1]);
        counts.(name) = table(uSubj, trialCountsPerSubj, 'VariableNames', {'subject','nTrials'});
        fprintf('\n----- %s: %d row(s), %d distinct trial(s) across %d subject(s) -----\n', ...
            name, height(Ts), sum(trialCountsPerSubj), numel(uSubj));
        disp(counts.(name));
        if any(trialCountsPerSubj == 0)
            fprintf(['[run_mixedEffectPipeline] WARNING: %s has a subject with 0 trials -- ' ...
                     'that subject contributes nothing to this stratum''s random effects.\n'], name);
        end

        fprintf('----- %s: running build_bandHierarchy (%d rows) -----\n', name, height(Ts));
        results.(name) = build_bandHierarchy(Ts);
    end
    results.counts = counts;

    if makePlots
        resultsList = {};
        for i = 1:numel(names)
            if isfield(results, names{i}), resultsList{end+1} = results.(names{i}); end %#ok<AGROW>
        end
        climLims = compute_bandHierarchyClim(resultsList, 'conditionEffect_p_corrected');
        for i = 1:numel(names)
            name = names{i};
            if ~isfield(results, name), continue; end
            fig = plot_bandHierarchyGrid(results.(name), 'conditionEffect_p_corrected', 0.05, ...
                mdlObj.nexon, name, climLims);
            fig.Name = name;
        end
    end
    fprintf('\n===== run_mixedEffectPipeline: done =====\n');
end
