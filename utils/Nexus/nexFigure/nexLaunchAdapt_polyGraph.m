function obj = nexLaunchAdapt_polyGraph(ctg)
% Launch adapter: adapt nexObj_polyGraph's signature to the common (ctg) call.
% Auto-discovered by nexLaunch_registry (figType = "polyGraph"). ctg rides the
% Parent slot; nexon/dfID_source come off the hub.
    obj = nexObj_polyGraph(ctg.nexon, ctg, [], ctg.dfID_source, [], ctg.dfID_source);
end
