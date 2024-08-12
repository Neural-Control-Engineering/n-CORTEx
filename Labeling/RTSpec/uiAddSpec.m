function uiAddSpec(dash)
    % coords = ginput
    dash.fh.UserData.specs.peak_params = [dash.fh.UserData.specs.peak_params; [1, 1, 1]];    
    drawSpecsUI(dash, dash.fh.UserData.specs, dash.fh.UserData.specs.freq,0);
    uiUpdateSpecs(dash);
end