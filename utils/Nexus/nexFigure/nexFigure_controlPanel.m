function nexFigure_controlPanel(nexObj)
    nexObj.Figure.fh = uifigure("Position",[10,10,410,420],"Color",[0,0,0]);
    panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,205,390,210],"BackgroundColor",[0,0,0]);
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,390,200],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel3.ph = uipanel(nexObj.Figure.panel2.ph,"Position",[5,5,380,185],"BackgroundColor",[0,0,0]);
    panel4.ph = uipanel(nexObj.Figure.panel3.ph,"Position",[120,5,255,175],"BackgroundColor",[0,0,0],"Scrollable","on");    
    % ROUTER SETUP
    % if ~isempty(nexObj.nexon.console.BASE.DTS)
    routerCfgParams = initializeRouterCfg(nexObj.nexon.console.BASE.DTS);
    valueChangedFcn = str2func("routerEntryChanged");
    % nexObj.Figure.panel1 = nexObj_cfgPanel(nexObj.nexon, nexObj, panel1, routerCfgParams, valueChangedFcn,[]);
    nexObj.Figure.panel1= nexObj_entryPanel(nexObj.nexon, panel1, routerCfgParams,valueChangedFcn, 20,10,1);
    % else
    %     routerCfgParams=struct;        
    % end    
    nexObj.nexon.console.BASE.router = nexObj.Figure.panel1; % assign handle to router slot
    nexObj.nexon.console.BASE.UserData.prevRouter.entryParams=nexObj.nexon.console.BASE.router.entryParams; % save previous router
    % CONTROL METHODS SETUP
    nexObj.Figure.panel4 = nexObj_listCfgPanel(nexObj.nexon, panel4, nexObj.averagingSelection,[]);
    % COMPUTE BUTTON
    nexObj.Figure.computeAvgButton = uibutton(nexObj.Figure.panel3.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"FontColor",[0,0,0],"Position",[10,10,100,150],"Text","","ButtonPushedFcn",@(~,~)nexCompute_nexonAverages(nexObj.nexon,[]));
    nexObj.Figure.computeAvgPanelTitle = uilabel(nexObj.Figure.panel3.ph, "Text","AVERAGE","Position",[10,162,100,20],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,"HorizontalAlignment","center");
    % delete(nexObj.Figure.computeAvgPanelTitle);
    % delete(nexObj.Figure.computeAvgButton)

end

% nexon.console.BASE.controlPanel.Figure.computeAvgButton.ButtonPushedFcn=@(~,~)nexCompute_nexonAverages(nexObj.nexon,[]);