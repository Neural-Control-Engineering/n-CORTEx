function uiRecoverPrevSpecs(dash)
    % assign previous params
    dash.fh.UserData.specs.peak_params = dash.fh.UserData.prevSpecs.peak_params;
    dash.fh.UserData.specs.aperiodic_params = dash.fh.UserData.prevSpecs.aperiodic_params;
    drawSpecsUI(dash, dash.fh.UserData.specs, dash.fh.UserData.specs.freq);
    uiUpdateSpecs(dash);
end