function nexFigure_controlPanel_npxls(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100,500,900,620],"Color",[0,0,0]);
    % plot panel
    nexObj.Figure.panel1.ph=uipanel(nexObj.Figure.fh,"Position",[5,5,700,580],"BackgroundColor",[0,0,0]);
    % controls
    nexObj.Figure.panel2.ph=uipanel(nexObj.Figure.fh,"Position",[710,5,185,580],"BackgroundColor",[0,0,0]);
    % loadDF_trial button
    nexObj.Figure.loadTrialDFButton=uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"Position",[5,540,175,35],"Text","","ButtonPushedFcn",@(~,~)loadTrialDF(nexObj,"NPXLS"));
    % captureStream button ...
    % 
end