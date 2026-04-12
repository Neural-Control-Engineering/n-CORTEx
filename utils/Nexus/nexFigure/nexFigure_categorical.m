function nexFigure_categorical(nexObj)

    % Panel sizing
    wInner  = 360;
    H_panel = 275;
    gap     = 5;

    nexObj.Figure.fh = uifigure("Position",[100,1260,900,720],"Color",[0,0,0]);
    % graphics panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,680],"BackgroundColor",[0,0,0]);
    %% Config Panel (scrollable sidebar)
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[710,5,wInner,680],"BackgroundColor",[0,0,0],"Scrollable","on");

    % Y layout — panels stacked bottom→top inside scrollable panel1:
    %   panel6        Y=5      opFcn
    %   panel5        Y=285    compFcn
    %   panel4        Y=565    items selection
    %   panel3        Y=845    categories selection
    %   panel_pointer Y=1125   RESULTS axis navigation (Window slots)
    %   panel_src     Y=1405   SRC + VW source selector
    %   panel2        Y=1685   pool cfg  ← top

    %% opFcn panel
    panel6.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 5, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0]);

    %% compFcn panel
    panel5.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 285, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0]);

    %% items selection panel
    panel4.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 565, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel4 = nexObj_listCfgPanel(nexObj.nexon, panel4, nexObj.selectionBus.items, []);

    %% categories selection panel
    panel3.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 845, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, panel3, nexObj.selectionBus.categories, []);

    %% Pointer panel — RESULTS axis navigation (Window panel slots, planned)
    panel_ptr.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 1125, wInner-2*gap, H_panel],...
        "BackgroundColor",[0,0,0],"Title","Pointer","ForegroundColor",nexObj.nexon.settings.Colors.cyberGreen);
    nexObj.Figure.panel_pointer = panel_ptr;

    %% SRC + VW + CLR panel — source selector and view group filter
    panel_src.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 1405, wInner-2*gap, H_panel],...
        "BackgroundColor",[0,0,0],"Title","View","ForegroundColor",nexObj.nexon.settings.Colors.cyberGreen);
    nexObj.Figure.panel_src = panel_src;
    nex_buildCollectorViewPanel(nexObj, panel_src.ph, H_panel);

    %% pool cfg panel  ← top of stack
    panel2.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 1685, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0]);
    poolCfgChangedFcn = str2func("poolCfgEntryChanged");
    try
        nexObj.Figure.panel2 = nexObj_poolCfgPanel_v3(nexObj, panel2, poolCfgChangedFcn);
    catch e
        disp(getReport(e));
    end

    %% UI CONTROL
    nexObj.Figure.dfIDEditField = uieditfield(nexObj.Figure.fh,...
        "BackgroundColor",[0,0,0],"FontColor",nexObj.nexon.settings.Colors.cyberGreen,...
        "Position",[710, 690, wInner, 25],"Value",nexObj.dfID_source,...
        "ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexObj.nexon,nexObj));
    nexObj.Figure.reportStatsButton = uibutton("state","Parent",nexObj.Figure.fh,...
        "Position",[5,690,25,25],"BackgroundColor",[0,0,0],...
        "ValueChangedFcn",@(~,~) nexObj.reportStats([]));

    %% GRAPHICS
    nexObj.Figure.panel0.tiles.t  = tiledlayout(nexObj.Figure.panel0.ph,1,1);
    nexObj.Figure.panel0.tiles.ax = nexttile(nexObj.Figure.panel0.tiles.t);
    colorAx_green(nexObj.Figure.panel0.tiles.ax);

end
