function nexRegister_figure(nexon, nexObj)
% nexRegister_figure  Record a launched figure in the session's reachable
% registry so router/trial traversal can find and refresh it.
%
%   nexRegister_figure(nexon, nexObj)
%
% Appends nexObj to nexon.UserData.launchedFigures, a cell array holding every
% figure launched through nexLaunch (INSPECT, auto, or direct). A CELL (not a
% handle array) because the figure classes are not a common concrete type —
% nexObj_pixelGram is `< handle`, the rest are `< nexObject`, so they cannot be
% concatenated into one typed array. Flat (not keyed) on purpose: two figures of
% the same type on the same source must both be tracked. Dead handles are pruned
% lazily by nexRefresh_launchedFigures.
%
% Skips duplicates (same handle already present) so re-registration is a no-op.

    if isempty(nexObj), return; end

    if ~isfield(nexon.UserData, 'launchedFigures') || ...
            ~iscell(nexon.UserData.launchedFigures)
        nexon.UserData.launchedFigures = {nexObj};
        return;
    end

    figs = nexon.UserData.launchedFigures;
    for i = 1:numel(figs)
        if isequal(figs{i}, nexObj), return; end     % already registered
    end
    nexon.UserData.launchedFigures{end+1} = nexObj;
end
