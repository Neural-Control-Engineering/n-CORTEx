function nexFigure_controlPanel_npxls(nexObj)
% Neuropixels realtime control panel. Three stacked sections in the right strip:
%   SORTER  — build (detectSequences) or load (loadSorter) the RTSort sorter
%   CAPTURE — start/stopCapture for a trial (direct proxy call == the same entry
%             the speedgoat path lands on via proxy_slrt.relayTransmission)
%   INSPECT — embedded figure launcher (nexLaunch_panel) for lfp / RTS_spk_* DFs
%
% Sorter/Capture reach the device proxy via nexObj.proxon.index_type2.npxls
% (already wired by nexObj_controlPanel_npxls). If no proxy is bound (offline),
% those controls disable and only INSPECT is live.

    nexon = nexObj.nexon;
    C = nexon.settings.Colors; GREEN = C.cyberGreen; BLACK = [0 0 0];

    px = [];
    try
        if isfield(nexObj.proxon.index_type2, 'npxls')
            px = nexObj.proxon.index_type2.npxls;
        end
    catch
    end

    nexObj.Figure.fh = uifigure("Name","npxls control","Position",[100,500,900,620],"Color",BLACK);
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,580],"BackgroundColor",BLACK);
    ctrl = uipanel(nexObj.Figure.fh,"Position",[710,5,185,580],"BackgroundColor",BLACK);
    nexObj.Figure.panel2.ph = ctrl;

    %% ---- SORTER ----
    pSort = uipanel(ctrl,"Position",[5,430,175,145],"BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","SORTER");
    uilabel(pSort,"Text","train (s)","Position",[5,95,70,22],"FontColor",GREEN);
    durField = uieditfield(pSort,"numeric","Position",[78,95,87,22],"Value",getDefault(px,'detectDurSec',60));
    buildBtn = uibutton(pSort,"Text","Build Sorter","Position",[5,65,160,26],"BackgroundColor",GREEN,"FontColor",BLACK,"ButtonPushedFcn",@(~,~)onBuild());
    loadBtn  = uibutton(pSort,"Text","Load Sorter...","Position",[5,37,160,24],"BackgroundColor",BLACK,"FontColor",GREEN,"ButtonPushedFcn",@(~,~)onLoad());
    sortStatus = uilabel(pSort,"Text",sorterText(px),"Position",[5,8,165,22],"FontColor",GREEN);

    %% ---- CAPTURE ----
    pCap = uipanel(ctrl,"Position",[5,300,175,120],"BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","CAPTURE");
    uilabel(pCap,"Text","trial #","Position",[5,68,55,22],"FontColor",GREEN);
    trialField = uieditfield(pCap,"numeric","Position",[62,68,103,22],"Value",1,"Limits",[1 255],"RoundFractionalValues","on");
    startBtn = uibutton(pCap,"Text","Start Capture","Position",[5,38,160,26],"BackgroundColor",GREEN,"FontColor",BLACK,"ButtonPushedFcn",@(~,~)onStart());
    stopBtn  = uibutton(pCap,"Text","Stop Capture","Position",[5,10,160,24],"BackgroundColor",BLACK,"FontColor",GREEN,"ButtonPushedFcn",@(~,~)onStop());

    %% ---- INSPECT (figure launcher) ----
    pInspect = uipanel(ctrl,"Position",[5,5,175,285],"BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","INSPECT");
    nexLaunch_panel(pInspect, nexon, ["lfp","RTS_spk"]);

    if isempty(px)
        [buildBtn.Enable, loadBtn.Enable, startBtn.Enable, stopBtn.Enable] = deal("off");
        sortStatus.Text = "no npxls proxy";
    end

    %% ---- callbacks ----
    function onBuild()
        buildBtn.Enable = "off"; drawnow;
        try
            px.detectSequences(durField.Value);
        catch e
            uialert(nexObj.Figure.fh, e.message, "Build failed");
        end
        sortStatus.Text = sorterText(px);
        buildBtn.Enable = "on";
    end

    function onLoad()
        try
            px.loadSorter([]);
        catch e
            uialert(nexObj.Figure.fh, e.message, "Load failed");
        end
        sortStatus.Text = sorterText(px);
    end

    function onStart()
        try
            px.startCapture(uint8(trialField.Value), []);   % same entry as the slrt relay
        catch e
            uialert(nexObj.Figure.fh, e.message, "Capture failed");
        end
    end

    function onStop()
        try
            px.stopCapture([], []);
        catch e
            uialert(nexObj.Figure.fh, e.message, "Stop failed");
        end
    end
end

function v = getDefault(px, field, def)
    v = def;
    if ~isempty(px) && isprop(px, field) && ~isempty(px.(field))
        v = px.(field);
    end
end

function t = sorterText(px)
    if isempty(px) || ~isequal(px.sorterReady, true)
        t = "sorter: none";
    elseif ~isempty(px.spkStatic) && isfield(px.spkStatic, 'unit_ids')
        t = sprintf("sorter: %d units", numel(px.spkStatic.unit_ids));
    else
        t = "sorter: ready";
    end
end
