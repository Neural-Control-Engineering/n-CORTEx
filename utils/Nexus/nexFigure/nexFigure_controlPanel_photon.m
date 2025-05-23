function nexFigure_controlPanel_photon(nexObj)
     %% DRAW FIGURE
    nexObj.Figure.fh = uifigure("Position",[100, 500, 1020, 620], "Color",[0,0,0]);
    % plot panel
    nexObj.Figure.panel1.ph=uipanel(nexObj.Figure.fh,"Position",[5,5,600,580],"BackgroundColor",[0,0,0]);

    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[610,5,400,580],"BackgroundColor",[0,0,0]); % opCfg
    % panel3.ph = uipanel(nexObj.Figure.fh,"Position",[610,5,200,285],"BackgroundColor",[0,0,0],"Scrollable","on");
    % panel4.ph = uipanel(nexObj.Figure.fh,"Position",[815,5,200,580],"BackgroundColor",[0,0,0],"Scrollable","on"); % visCfg
    % inputs (buttons)
    % load rig
    % nexObj.Figure.loadRigButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"Position",[10,10,100,150],"Text","","ButtonPushedFcn",@(~,~)ctxControl_photon_loadRig(nexObj.nexon,[]));
    nexObj.Figure.loadRigButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",[1,1,1],"FontColor",[0,0,0],"Position",[10,10,100,150],"Text","","ButtonPushedFcn",@(~,~)ctxControl_photon_loadRig(nexObj.nexon,[]));
    % load objective
    nexObj.Figure.loadObjective = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",[1,1,1],"FontColor",[0,0,0],"Position",[10,10,100,150],"Text","","ButtonPushedFcn",@(~,~)ctxControl_photon_loadObjective(nexObj.nexon,[]));
    % operation control panel
end