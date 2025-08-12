function nexFigure_controlPanel_photon(nexObj)
    % color settings
    color1 = [1,1,1];
    stagePositionList = fieldnames(nexObj.nCORTEx.params.expmntCfg_target.targets.photon.stagePositions);
    stagePositionList_subject = fieldnames(nexObj.nCORTEx.params.subjectCfg.targets.photon.stagePositions);
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
    %% stage position control LOADING CONTROL
    nexObj.Figure.initializeMicroscope = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,225,380,50],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_initializeMicroscope(nexObj));
    nexObj.Figure.updatePositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,40,185,150],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_updateStagePosition(nexObj, "load"),"Enable","off");
    nexObj.Figure.resetPositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,10,185,25],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_resetStagePosition(nexObj,"load"),"Enable","off");        
    % nexObj.Figure.selectPositionDropDown = uidropdown(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,195,155,25],"Items",stagePositionList,"ValueChangedFcn",@(~,~)photonCtrl_selectPositionDropDownValueChanged(src, event, nexObj));
    nexObj.Figure.selectPositionDropDown = uidropdown(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[10,195,155,25],"Items",stagePositionList);
    nexObj.Figure.addPositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[170,195,25,25],"ButtonPushedFcn",@(~,~)photonCtrl_addStagePosition(nexObj,"load"),"Text","+");
    %% stage position control (subject) IMAGING CONTROL
    
    nexObj.Figure.updatePositionButton_subject_over = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[205,144,185,45],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_updateStagePosition(nexObj,"over"),"Enable","off"); % idx 3
    nexObj.Figure.updatePositionButton_subject_hover = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[205,92,185,45],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_updateStagePosition(nexObj,"hover"),"Enable","off"); % idx 4
    nexObj.Figure.updatePositionButton_subject_image = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[205,40,185,45],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_updateStagePosition(nexObj,"image"),"Enable","off"); % idx 5
    nexObj.Figure.resetPositionButton_subject = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[205,10,185,25],"Text","","ButtonPushedFcn",@(~,~)photonCtrl_resetStagePosition(nexObj,"image"),"Enable","off"); % idx 4
    % nexObj.Figure.selectPositionDropDown_subject = uidropdown(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[205,195,155,25],"Items",stagePositionList_subject,"ValueChangedFcn",@(~,~)photonCtrl_selectImagePositionDropDownValueChanged(src, event, nexObj));
    nexObj.Figure.selectPositionDropDown_subject = uidropdown(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[205,195,155,25],"Items",stagePositionList_subject);
    nexObj.Figure.addImagePositionButton = uibutton(nexObj.Figure.panel2.ph,"BackgroundColor",color1,"FontColor",[0,0,0],"Position",[365,195,25,25],"ButtonPushedFcn",@(~,~)photonCtrl_addStagePosition(nexObj,"image"),"Text","+");

    % lisCfg 
    % nexObj.Figure.SubjectLocationsList = nexObj_listCfgPanel(nexObj.nexon, panel3, nexObj.visSelection, [3,1]);
    % set current position as buttons
    % operation control panel
end