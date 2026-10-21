function climLims = compute_bandHierarchyClim(resultsList, valueCol)
% compute_bandHierarchyClim  Shared color-axis limits across several
% build_bandHierarchy results tables (e.g. the 4 CCI/side strata), so
% plot_bandHierarchyGrid can render every stratum on the SAME scale
% instead of each auto-scaling to its own data range -- without this, a
% "bright" cell in one stratum's own scale could be a completely
% different absolute value than a "bright" cell in another's, making
% cross-stratum visual comparison misleading. Mirrors
% plot_bandHierarchyGrid.m's own internal valueCol transform exactly, so
% the climLims this returns means the same thing fed back into it via its
% climLimsOverride parameter.
%
%   resultsList : cell array of build_bandHierarchy output tables (one
%                 per stratum) -- empty/0-row/missing-column entries are
%                 skipped, not errored on.
%   valueCol    : optional, default 'conditionEffect_p_corrected'.
%
%   climLims : [0, hi] for a 'p_'-containing column (-log10(p) scale,
%              matching plot_bandHierarchyGrid's own isPValue branch), or
%              [-m, m] for anything else (e.g. 'conditionEffect',
%              symmetric diverging scale).

    if nargin < 2 || isempty(valueCol), valueCol = 'conditionEffect_p_corrected'; end
    isPValue = contains(valueCol, 'p_');

    allVals = [];
    for i = 1:numel(resultsList)
        R = resultsList{i};
        if isempty(R) || height(R) == 0 || ~ismember(valueCol, R.Properties.VariableNames)
            continue;
        end
        allVals = [allVals; R.(valueCol)(:)]; %#ok<AGROW>
    end

    if isPValue
        plotVals = -log10(max(allVals, eps));
        finiteVals = plotVals(isfinite(plotVals));
        hi = max(finiteVals, [], 'omitnan');
        if isempty(hi) || hi <= 0, hi = 1; end
        climLims = [0, hi];
    else
        m = max(abs(allVals), [], 'omitnan');
        if isempty(m) || m == 0, m = 1; end
        climLims = [-m, m];
    end
end
