function strataT = stratifyMixedEffectT(T)
% stratifyMixedEffectT  The canonical CCI x side four-way stratification
% split, factored out of run_mixedEffectPipeline.m so any other consumer
% (plot_mixedEffectTrajectory.m, future diagnostics) filters EXACTLY the
% same rows that produced a given stratum's build_bandHierarchy results --
% never a second, independently-maintained copy of this filter that could
% drift out of sync with the real one.
%
% Pre-CCI and post-CCI NEVER share a model fit or a multiple-comparisons
% pool, and neither do left/right -- see run_mixedEffectPipeline.m's own
% header for why (injury-induced hyperalgesia must not leak into a
% baseline-sensory-coding question or vice versa).
%
%   T : build_bandPowerRegionTable output (or results.T from
%       run_mixedEffectPipeline) -- must have side/cci columns.
%
%   strataT : struct with fields preCCI_L/preCCI_R/postCCI_L/postCCI_R,
%             each T filtered to that stratum (possibly 0 rows).

    if ~ismember('side', T.Properties.VariableNames) || ~ismember('cci', T.Properties.VariableNames)
        error('stratifyMixedEffectT:noPhase', ...
            ['T has no side/cci columns -- mdlObj.STAT needs a sessionLabel_phase ' ...
             'column (e.g. "L-hind-paw-CCI") for the four-way stratification this ' ...
             'pipeline runs.']);
    end
    strataT = struct( ...
        'preCCI_L',  T(~T.cci & T.side == "L", :), ...
        'preCCI_R',  T(~T.cci & T.side == "R", :), ...
        'postCCI_L', T( T.cci & T.side == "L", :), ...
        'postCCI_R', T( T.cci & T.side == "R", :));
end
