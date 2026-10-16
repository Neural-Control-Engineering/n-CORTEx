function obj = nexLaunchAdaptMdl_bar(mdlObj)
% Launch adapter: open a nexObj_bar wired to a live mdlObj. Auto-discovered
% by nexLaunch_registryMdl (figType = "bar"). See nexObj_bar's own header /
% nexObject.wireModelSource for the source-watching construction path.
    obj = nexObj_bar(mdlObj);
end
