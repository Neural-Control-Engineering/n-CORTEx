function nexFigure_controlPanel_photon(nexObj)
    % color settings
    color1 = [1,1,1];
    stagePositionList = fieldnames(nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions);
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
    % rig position control
    nexObj.Figure.updatePositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,40,180,150],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_updateStagePosition(nexObj));
    nexObj.Figure.savePositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,10,180,25],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_resetStagePosition(nexObj));        
    nexObj.Figure.selectPositionDropDown = uidropdown(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,195,150,25],"Items",stagePositionList,"ValueChangedFcn",@(~,~)photonCtrl_selectPositionDropDownValueChanged(nexObj));
    nexObj.Figure.addPositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[165,195,25,25],"ButtonPushedFcn",@(~,~)photonCtrl_addStagePosition(nexObj),"Text","+");
    % move to image subject
    nexObj.Figure.updatePositionButton_subject_over = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[250,110,100,40],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_locateSubject_over(nexObj,[])); % idx 3
    nexObj.Figure.updatePositionButton_subject_hover = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[250,60,100,40],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_locateSubject_hover(nexObj,[])); % idx 4
    nexObj.Figure.updatePositionButton_subject_image = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[250,10,100,40],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_locateSubject(nexObj,[])); % idx 5
    nexObj.Figure.saveNewPositionButton_subject = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[250,165,100,25],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_setSubjectLocation(nexObj,[]));
    % lisCfg 
    % nexObj.Figure.SubjectLocationsList = nexObj_listCfgPanel(nexObj.nexon, panel3, nexObj.visSelection, [3,1]);
    % set current position as buttons
    % operation control panel
end