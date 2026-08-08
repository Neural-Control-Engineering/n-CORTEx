function obj = nexLaunchAdapt_monoGraph(ctg)
% Launch adapter: adapt nexObj_monoGraph's signature to the common (ctg) call.
% Auto-discovered by nexLaunch_registry (figType = "monoGraph"). ctg rides the
% Parent slot; nexon/dfID_source come off the hub.
    obj = nexObj_monoGraph(ctg, [], ctg.nexon, ctg.dfID_source, [], [], ctg.dfID_source);
end
