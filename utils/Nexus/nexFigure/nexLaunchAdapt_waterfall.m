function obj = nexLaunchAdapt_waterfall(ctg)
% Launch adapter: adapt nexObj_waterfall's signature to the common (ctg) call.
% Auto-discovered by nexLaunch_registry (figType = "waterfall"). ctg rides the
% Parent slot; nexon/dfID_source come off the hub.
    obj = nexObj_waterfall(ctg.nexon, ctg, [], ctg.dfID_source, [], []);
end
