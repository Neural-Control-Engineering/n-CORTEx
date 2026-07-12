function nexRefresh_launchedFigures(nexon)
% nexRefresh_launchedFigures  Repopulate every launched figure for the current
% router/trial selection, and prune closed ones.
%
%   nexRefresh_launchedFigures(nexon)
%
% Walks nexon.UserData.launchedFigures (populated by nexRegister_figure via
% nexLaunch) and calls reloadFromRouter() on each live figure — the generic
% per-figure refresh (re-read dfID_source for the selected trial, operate,
% visualize). Handles whose window was closed are dropped from the registry.
% Figures lacking reloadFromRouter (e.g. nexObj_pixelGram, a `< handle` partner
% view) stay registered but are not router-refreshed.
%
% Called from routerEntryChanged alongside the legacy NPXLS/SLRT scope walk.

    if ~isfield(nexon.UserData, 'launchedFigures'), return; end

    figs = nexon.UserData.launchedFigures;
    keep = {};
    for i = 1:numel(figs)
        f = figs{i};
        try
            if isvalid(f) && isvalid(f.Figure.fh)
                keep{end+1} = f;                        %#ok<AGROW> alive → retain
                if ismethod(f, 'reloadFromRouter')
                    f.reloadFromRouter();               % stale trial/dfID → caught below
                end
            end
        catch e
            disp(getReport(e));
        end
    end
    nexon.UserData.launchedFigures = keep;
end
