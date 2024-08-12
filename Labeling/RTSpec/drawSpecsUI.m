function drawSpecsUI(dash, specs, freq)
    cyberGreen = [0.24,0.94,0.46];
    yStep = 23;
    xStep = 60;
    editFieldStartPos_peaks = [20,535,30,20];
    peaks = specs.peak_params;
    fract = specs.aperiodic_params;
    % draw labels
    % PEAKS
    dash.panel3.CFLabel = uilabel(dash.panel3.ph1,"Position",[20,560,30,20],"Text","CF","FontColor",cyberGreen,"FontSize",18,"HorizontalAlignment","center");
    dash.panel3.BWLabel = uilabel(dash.panel3.ph1,"Position",[80,560,30,20],"Text","BW","FontColor",cyberGreen,"FontSize",18);
    dash.panel3.PWLabel = uilabel(dash.panel3.ph1,"Position",[140,560,30,20],"Text","PW","FontColor",cyberGreen,"FontSize",18);
    for i = 1:size(peaks,1)
        CF = peaks(i,1); % CF
        BW = peaks(i,3); % BW
        PW = peaks(i,2); % PW
        yPtr_peaks = (i-1) * yStep;
        editFieldPos_peaks = editFieldStartPos_peaks - [0, yPtr_peaks, 0, 0]
        specTag = sprintf("spc%d",i);
        dash.panel3.(specTag).CFEntry = uieditfield(dash.panel3.ph1,"numeric","FontSize",14,"FontColor",cyberGreen,"Position",editFieldPos_peaks,"BackgroundColor",[0,0,0]);
        dash.panel3.(specTag).BWEntry = uieditfield(dash.panel3.ph1,"numeric","FontSize",14,"FontColor",cyberGreen,"Position",editFieldPos_peaks+[xStep,0,0,0],"BackgroundColor",[0,0,0]);
        dash.panel3.(specTag).PWEntry = uieditfield(dash.panel3.ph1,"numeric","FontSize",14,"FontColor",cyberGreen,"Position",editFieldPos_peaks+[xStep*2,0,0,0],"BackgroundColor",[0,0,0]);
    end
    % FRACTAL
    dash.panel3.EXPLabel = uilabel(dash.panel3.ph1,"Position",[15,150,50,20],"Text","EXP","FontColor",cyberGreen,"FontSize",18,"HorizontalAlignment","center");
    dash.panel3.BiasLabel = uilabel(dash.panel3.ph1,"Position",[75,150,50,20],"Text","Bias","FontColor",cyberGreen,"FontSize",18,"HorizontalAlignment","center");
    dash.panel3.EXPEntry = uieditfield(dash.panel3.ph1,"numeric","FontSize",14,"FontColor",cyberGreen,"Position",[15,120,50,20],"BackgroundColor",[0,0,0]);
    dash.panel3.BiasEntry = uieditfield(dash.panel3.ph1,"numeric","FontSize",14,"FontColor",cyberGreen,"Position",[15,120,50,20]+[xStep,0,0,0],"BackgroundColor",[0,0,0]);
    
    
end