function figs = plot_mixedEffectResults(results, mdlObj, valueCol, sigThreshold)
% plot_mixedEffectResults  Regenerate the per-stratum dark-mode heatmaps
% from an already-computed run_mixedEffectPipeline results struct, without
% re-running build_bandPowerRegionTable/build_bandHierarchy.
%
%   results      : output of run_mixedEffectPipeline (struct with T,
%                  preCCI_L, preCCI_R, postCCI_L, postCCI_R, counts -- any
%                  stratum that was skipped there (0 rows) is simply
%                  skipped here too).
%   mdlObj       : the same mdlObj passed to run_mixedEffectPipeline --
%                  only mdlObj.nexon is used here, to depth-order the
%                  chans axis exactly as the live pipeline call does.
%   valueCol     : optional, default 'conditionEffect_p_corrected' --
%                  forwarded to plot_bandHierarchyGrid.
%   sigThreshold : optional, default 0.05 -- forwarded to
%                  plot_bandHierarchyGrid.
%
%   figs : struct, one figure handle per stratum actually plotted. All
%          plotted strata share the SAME color-axis limits
%          (compute_bandHierarchyClim, computed once across every stratum
%          actually present) so a "bright" cell means the same thing in
%          every figure.

    if nargin < 3 || isempty(valueCol), valueCol = 'conditionEffect_p_corrected'; end
    if nargin < 4, sigThreshold = 0.05; end

    strataNames = {'preCCI_L', 'preCCI_R', 'postCCI_L', 'postCCI_R'};
    present = {};
    for i = 1:numel(strataNames)
        if isfield(results, strataNames{i}) && ~isempty(results.(strataNames{i}))
            present{end+1} = strataNames{i}; %#ok<AGROW>
        end
    end
    resultsList = cellfun(@(n) results.(n), present, 'UniformOutput', false);
    climLims = compute_bandHierarchyClim(resultsList, valueCol);

    figs = struct();
    for i = 1:numel(strataNames)
        name = strataNames{i};
        if ~isfield(results, name) || isempty(results.(name))
            fprintf('[plot_mixedEffectResults] %s not present in results -- skipped\n', name);
            continue;
        end
        fig = plot_bandHierarchyGrid(results.(name), valueCol, sigThreshold, mdlObj.nexon, name, climLims);
        fig.Name = name;
        figs.(name) = fig;
    end
end
