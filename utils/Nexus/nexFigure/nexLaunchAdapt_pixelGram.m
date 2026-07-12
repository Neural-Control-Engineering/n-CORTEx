function obj = nexLaunchAdapt_pixelGram(ctg)
% Launch adapter: adapt nexObj_pixelGram's signature to the common (ctg) call.
% Auto-discovered by nexLaunch_registry (figType = "pixelGram"). ctg rides the
% Partner slot; nexon comes off the hub.
    obj = nexObj_pixelGram(ctg, ctg.nexon);
end
