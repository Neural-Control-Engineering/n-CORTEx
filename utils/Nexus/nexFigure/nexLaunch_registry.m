function reg = nexLaunch_registry()
% nexLaunch_registry  Auto-discovered figure-launch map.
%
% Scans this folder for nexLaunchAdapt_<figType>.m companion adapters and
% returns a struct mapping <figType> -> @nexLaunchAdapt_<figType>. Each adapter
% adapts one figure constructor's (heterogeneous) signature to the common (ctg)
% call — the single place per-figure launch knowledge lives, co-located with the
% figure. See nexLaunch (the primitive) and nexLaunch_auto (the config-driven
% automation) for the consumers.
%
% Add a launchable figure = drop a nexLaunchAdapt_<figType>.m file next to the
% others (signature: function obj = nexLaunchAdapt_<figType>(ctg)). It appears in
% every launcher dropdown (nexLaunch_panel reads fieldnames(reg)) and every
% nexLaunch_auto config with no edit here.
%
% ctg supplies both nexon (ctg.nexon) and source id (ctg.dfID_source).

    prefix = 'nexLaunchAdapt_';
    here   = fileparts(mfilename('fullpath'));
    files  = dir(fullfile(here, [prefix '*.m']));

    reg = struct();
    for k = 1:numel(files)
        funcName = files(k).name(1:end-2);              % strip trailing '.m'
        figType  = funcName(numel(prefix)+1:end);       % strip the prefix
        reg.(figType) = str2func(funcName);
    end
end
