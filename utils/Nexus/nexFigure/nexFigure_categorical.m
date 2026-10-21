function nexFigure_categorical(nexObj)

    % Panel sizing
    wInner  = 360;
    H_panel = 275;
    gap     = 5;

    % categories/items key counts are dynamic — one key per available
    % category (session label + signal types + task vars + h5 fields +
    % DF dims), easily 10-20+ — unlike the small fixed key sets (2-4)
    % the other selectionBus panels carry. nexObj_listCfgPanel's own
    % per-key width (panelWidth/(nKeys+0.3), floored so it never goes
    % non-positive) shrinks to that floor whenever the CONTAINER isn't
    % sized for the actual key count, producing uncomfortably narrow
    % listboxes. So size panel3/panel4's own width here, per bus, to
    % keep each listbox at a comfortable slot width — originally the
    % ~150px the fixed /2.3 divisor gave for 2 keys, bumped to ~190px
    % (user-reported: these two buses were still too narrow even with
    % this per-key container scaling in place, same ~25% bump as
    % controlPanel's averagingSelection) — and let them overflow past
    % panel1's width into its existing horizontal scroll.
    slotWidth = 190;
    nCatKeys  = max(numel(fieldnames(nexObj.selectionBus.categories.selKeys)), 1);
    nItemKeys = max(numel(fieldnames(nexObj.selectionBus.items.selKeys)), 1);
    wCategories = max(wInner - 2*gap, slotWidth * (nCatKeys + 0.3));
    wItems      = max(wInner - 2*gap, slotWidth * (nItemKeys + 0.3));

    nexObj.Figure.fh = uifigure("Position",[100,1260,900,720],"Color",[0,0,0]);
    % graphics panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,680],"BackgroundColor",[0,0,0]);
    %% Config Panel (scrollable sidebar)
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[710,5,wInner,680],"BackgroundColor",[0,0,0],"Scrollable","on");

    % Y layout — panels stacked bottom→top inside scrollable panel1:
    %   panel6    Y=5      opFcn
    %   panel5    Y=285    compFcn
    %   panel4    Y=565    items selection
    %   panel3    Y=845    categories selection
    %   panel_src Y=1125   SRC / CLR / CMP / GRP source+compare selector
    %   panel2    Y=1405   pool cfg  ← top
    %
    % NOTE: no Pointer panel — categories/items buses serve that role
    % NOTE: no VW panel — categories bus selects group dimensions natively

    %% opFcn panel
    panel6.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 5, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0]);

    %% compFcn panel
    panel5.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 285, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0]);

    %% items selection panel
    panel4.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 565, wItems, H_panel],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel4 = nexObj_listCfgPanel(nexObj.nexon, panel4, nexObj.selectionBus.items, []);

    %% categories selection panel
    panel3.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 845, wCategories, H_panel],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel3 = nexObj_listCfgPanel(nexObj.nexon, panel3, nexObj.selectionBus.categories, []);

    %% SRC / CLR / CMP / GRP panel — source + compare selector
    % No Pointer panel: categories/items buses serve that role for categorical.
    % No VW panel: categories bus natively selects group dimensions.
    panel_src.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 1125, wInner-2*gap, H_panel],...
        "BackgroundColor",[0,0,0],"Title","View","ForegroundColor",nexObj.nexon.settings.Colors.cyberGreen, "Scrollable","on");
    nexObj.Figure.panel_src = panel_src;
    nex_buildCollectorViewPanel(nexObj, panel_src.ph, H_panel);

    %% pool cfg panel  ← top of stack
    panel2.ph = uipanel(nexObj.Figure.panel1.ph,"Position",[gap, 1405, wInner-2*gap, H_panel],"BackgroundColor",[0,0,0]);
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
    nexObj.applyHeadline();
end
