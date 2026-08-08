function obj = nexLaunchAdapt_monoGram(ctg)
% Launch adapter: adapt nexObj_monoGram's signature to the common (ctg) call.
% Auto-discovered by nexLaunch_registry (figType = "monoGram"). ctg rides the
% Parent slot; nexon/dfID_source come off the hub.
    obj = nexObj_monoGram(ctg.nexon, ctg, ctg.dfID_source, [], [], ctg.dfID_source);
end
