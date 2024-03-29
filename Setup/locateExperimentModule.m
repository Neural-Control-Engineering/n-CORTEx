function slrt_out = locateExperimentModule(slrt)    
    if ~isfield(slrt,'experimentModulePath')
        [file, fldr] = uigetfile('*.slx','Select a simulink model');
        slrt_out.experimentModulePath = fldr;
    elseif isempty(slrt.experimentModulePath)
        [file, fldr] = uigetfile('*.slx','Select a simulink model');
        slrt_out.experimentModulePath = fldr;
    else
        slrt_out = slrt;
    end
end