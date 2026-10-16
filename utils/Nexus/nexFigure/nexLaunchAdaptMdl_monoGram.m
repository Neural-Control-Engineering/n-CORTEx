function obj = nexLaunchAdaptMdl_monoGram(mdlObj)
% Launch adapter: open a nexObj_monoGram wired to a live mdlObj (2-D
% accuracy/weights heatmap over the CTG-combo x SWP domain). Auto-discovered
% by nexLaunch_registryMdl (figType = "monoGram"). nexon/dfID_source are
% resolved from mdlObj itself via nexObject.resolveNexonFromSource — see the
% mdlObj-sourced branch of nexObj_monoGram's own constructor.
    obj = nexObj_monoGram([], mdlObj);
end
