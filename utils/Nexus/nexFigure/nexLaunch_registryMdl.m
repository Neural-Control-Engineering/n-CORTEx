function reg = nexLaunch_registryMdl()
% nexLaunch_registryMdl  Auto-discovered figure-launch map, mdlObj-sourced.
%
% Scans this folder for nexLaunchAdaptMdl_<figType>.m companion adapters and
% returns a struct mapping <figType> -> @nexLaunchAdaptMdl_<figType>. Each
% adapter adapts one figure constructor's (heterogeneous) signature to the
% common (mdlObj) call — the single place per-figure launch-from-mdlObj
% knowledge lives, co-located with the figure. Parallel to nexLaunch_registry
% (the ctg-sourced counterpart) — a genuinely separate registry rather than a
% shared one because the two adapter conventions take different call
% arguments (ctg vs mdlObj) and are never interchangeable. See
% nexFigure_addLaunchControls (the consumer).
%
% Add a launchable-from-mdlObj figure = drop a
% nexLaunchAdaptMdl_<figType>.m file next to the others (signature:
% function obj = nexLaunchAdaptMdl_<figType>(mdlObj)). It appears in every
% nexFigure_addLaunchControls dropdown with no edit here.

    prefix = 'nexLaunchAdaptMdl_';
    here   = fileparts(mfilename('fullpath'));
    files  = dir(fullfile(here, [prefix '*.m']));

    reg = struct();
    for k = 1:numel(files)
        funcName = files(k).name(1:end-2);              % strip trailing '.m'
        figType  = funcName(numel(prefix)+1:end);        % strip the prefix
        reg.(figType) = str2func(funcName);
    end
end
