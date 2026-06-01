function nexFigure_categorical(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100,1260,900,720],"Color",[0,0,0]);
    % graphics panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,680],"BackgroundColor",[0,0,0]);
    %% Config Panel
    nexObj.Figure.panel1.ph =  uipanel(nexObj.Figure.fh,"Position",[710,5,185,680],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel3.ph = uipanel(nexObj.Figure.panel2.ph,"Position",[5,80,160,630],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel4.ph = uipanel(nexObj.Figure.panel2.ph,"Position",[5,5,160,75],"BackgroundColor",[0,0,0],"Scrollable","on");    
    %% pooling panel    
    panel2.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5,1120,180,275],"BackgroundColor",[0,0,0]);
    poolCfgChangedFcn = str2func("poolCfgEntryChanged");
    try
        nexObj.Figure.panel2 = nexObj_poolCfgPanel_v3(nexObj, panel2, poolCfgChangedFcn);
    catch e
        disp(getReport(e));
    end
    %% category/item selection panel
    % categories selection
    panel3.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5, 845, 180, 275],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, panel3, nexObj.selectionBus.categories,[]);
    % items selection
    panel4.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5, 565, 180, 275], "BackgroundColor",[0,0,0],"Scrollable","on");    
    nexObj.Figure.panel4 = nexObj_listCfgPanel(nexObj.nexon, panel4, nexObj.selectionBus.items,[]);
    % compFcn panel (if entered)
    panel5.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5, 285, 180, 275], "BackgroundColor",[0,0,0],"Scrollable","on");    
    % opFcn panel (if entered)    
    panel6.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[5, 5, 180, 275], "BackgroundColor",[0,0,0]);    
    %% UI CONTROL
    % axis control (select primary axis)
    % nexObj.Figure.axSelDropDown = uidropdown(nexObj.Figure.fh,"Position",[35, 800, 80, 25], "BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"Items",fieldnames(nexObj.DF_postOp.ptr));
    % nexObj.Figure.axSelSpinner = uispinner(nexObj.Figure.fh);
    % dfID control
    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,"Position",[710, 690, 185, 25], "Value",nexObj.dfID_source,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexObj.nexon,nexObj));
    nexObj.Figure.reportStatsButton = uibutton("state","Parent",nexObj.Figure.fh,"Position",[5,690,25,25],"BackgroundColor",[0,0,0],"ValueChangedFcn",@(~,~) nexObj.reportStats([]));
    %% GRAPHICS
    nexObj.Figure.panel0.tiles.t = tiledlayout(nexObj.Figure.panel0.ph,1,1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);    
    % violinplot(tbl,["X1","X3"],["Y1","Y2"]);
    % nexObj.Figure.panel0.graphics.canvas =violinplot(nexObj.Figure.panel0.tiles.ax,(nexObj.STAT.f),nexObj.STAT.df,GroupByColor=nexObj.STAT.chans);
    % nexObj.drawCanvas();
    % nexObj.Figure.panel0.graphics.canvas =  violinplot(nexObj.Figure.panel0.tiles.ax, nexObj.STAT.df, nexObj.STAT.sessionLabel_phase, nexObj.STAT.chans, nexObj.STAT.f);
    colorAx_green(nexObj.Figure.panel0.tiles.ax);

end