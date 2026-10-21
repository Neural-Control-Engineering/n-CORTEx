function cmap = nexVis_legacyCyberGreenColormap(nexon)
% nexVis_legacyCyberGreenColormap  The ORIGINAL monoGram colormap -- a
% pre-saved 256x3 RGB table (Visualization/RealtimeVis/cmap-cyberGreen.mat),
% non-linear and desaturated through its midpoint, as opposed to
% nexVis_sequentialColormap's clean linear black->cyberGreen->white
% gradient. Reinstated here (not deleted) for sources WITHOUT a
% sigThreshold column -- per explicit request, the saturated gradient is
% gated to the p-value use case only, not a blanket replacement of
% monoGram's long-standing default look.
%
%   nexon : root Nexon handle, used only to resolve the repo path the
%           same way nexFigure_monoGram.m's original construction-time
%           load did.
%
%   cmap : 256x3 RGB colormap.
    persistent cachedCT
    if isempty(cachedCT)
        matPath = fullfile(nexon.console.BASE.params.paths.repo_path, ...
            "Visualization/RealtimeVis/cmap-cyberGreen.mat");
        S = load(matPath, 'CT');
        cachedCT = S.CT;
    end
    cmap = cachedCT;
end
