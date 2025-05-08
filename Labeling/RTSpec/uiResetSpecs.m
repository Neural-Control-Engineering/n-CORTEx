function uiResetSpecs(dash)
    dash.fh.UserData.specs.peak_params = dash.fh.UserData.specs_backup.peak_params;
    dash.fh.UserData.specs.aperiodic_params = dash.fh.UserData.specs_backup.aperiodic_params;   
    drawSpecsUI(dash, dash.fh.UserData.specs, dash.fh.UserData.specs.freq,1);
    uiUpdateSpecs(dash);
end