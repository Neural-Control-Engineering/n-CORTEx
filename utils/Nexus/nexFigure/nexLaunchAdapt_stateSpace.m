function obj = nexLaunchAdapt_stateSpace(ctg)
% Launch adapter: adapt nexObj_stateSpace's signature to the common (ctg) call.
% Auto-discovered by nexLaunch_registry (figType = "stateSpace"). ctg rides the
% Parent slot; Partner is left empty (it is a genuinely optional second partner,
% NOT the hub — see nexLaunch factory notes); nexon/dfID_source come off the hub.
    obj = nexObj_stateSpace(ctg.nexon, ctg, [], ctg.dfID_source, []);
end
