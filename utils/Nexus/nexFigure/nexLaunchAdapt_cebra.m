function obj = nexLaunchAdapt_cebra(ctg)
% Launch adapter: build mdlObj_cebra from the categorical hub. Auto-discovered
% by nexLaunch_registry (figType = "cebra"). The ctg rides the Parent slot;
% nexon and source dfID come off the hub (ctg.nexon, ctg.dfID_source).
%
% Flow: Fit -> Transform writes the projected dfID (cebra_<source>) into the
% DTS; pair with nexObj_stateSpace on that output for trajectory visualization.
%
% DM format is "cebra" (stat2dm_cebra): stacks X and encodes trial labels as Y
% for contrastive learning. sampleAxes = ["trial","t"] captures temporal
% structure across the trial sequence.
    obj = mdlObj_cebra(ctg, [], ctg.dfID_source);
end
