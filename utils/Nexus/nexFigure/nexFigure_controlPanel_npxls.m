function nexFigure_controlPanel_npxls(nexObj)
% Neuropixels realtime control panel. Two stacked sections in the right strip:
%   SORTER  — build (detectSequences) or load (loadSorter) the RTSort sorter
%   CAPTURE — start/stopCapture for a trial (direct proxy call == the same entry
%             the speedgoat path lands on via proxy_slrt.relayTransmission)
% plus a SINK button to flush the in-memory capture DTS to disk.
%
% Sorter/Capture reach the device proxy via nexObj.proxon.index_type2.npxls
% (already wired by nexObj_controlPanel_npxls). If no proxy is bound (offline),
% those controls disable.
%
% Figure launching is handled by nexPanel_launcher (started from startNexus)
% and is no longer embedded here.

    nexon = nexObj.nexon;
    C = nexon.settings.Colors; GREEN = C.cyberGreen; BLACK = [0 0 0];

    % Resolve the device proxy LIVE from the proxon on every action (getPx),
    % never cache it. configureTargetProxies rebuilds proxy_npxls and overwrites
    % proxon.index_type2.npxls on every (re)configure/reconnect, so a handle
    % cached at construction goes stale — Load would flip sorterReady on the
    % orphaned proxy while the speedgoat-driven capture reads the live one.
    px = getPx();

    nexObj.Figure.fh = uifigure("Name","npxls control","Position",[100,500,900,620],"Color",BLACK);
    nexObj.Figure.fh.CloseRequestFcn = @(fh,~)onClose(fh);
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,580],"BackgroundColor",BLACK);
    ctrl = uipanel(nexObj.Figure.fh,"Position",[710,255,185,330],"BackgroundColor",BLACK);
    nexObj.Figure.panel2.ph = ctrl;

    %% ---- SORTER ----
    pSort = uipanel(ctrl,"Position",[5,175,175,145],"BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","SORTER");
    uilabel(pSort,"Text","train (s)","Position",[5,95,70,22],"FontColor",GREEN);
    durField = uieditfield(pSort,"numeric","Position",[78,95,87,22],"Value",getDefault(px,'detectDurSec',60));
    buildBtn = uibutton(pSort,"Text","Build Sorter","Position",[5,65,160,26],"BackgroundColor",GREEN,"FontColor",BLACK,"ButtonPushedFcn",@(~,~)onBuild());
    loadBtn  = uibutton(pSort,"Text","Load...","Position",[5,37,78,24],"BackgroundColor",BLACK,"FontColor",GREEN,"ButtonPushedFcn",@(~,~)onLoad());
    saveBtn  = uibutton(pSort,"Text","Save...","Position",[87,37,78,24],"BackgroundColor",BLACK,"FontColor",GREEN,"ButtonPushedFcn",@(~,~)onSave());
    sortStatus = uilabel(pSort,"Text",sorterText(px),"Position",[5,8,165,22],"FontColor",GREEN);

    %% ---- CAPTURE ----
    pCap = uipanel(ctrl,"Position",[5,45,175,120],"BackgroundColor",BLACK,"ForegroundColor",GREEN,"Title","CAPTURE");
    uilabel(pCap,"Text","trial #","Position",[5,68,55,22],"FontColor",GREEN);
    trialField = uieditfield(pCap,"numeric","Position",[62,68,103,22],"Value",1,"Limits",[1 255],"RoundFractionalValues","on");
    startBtn = uibutton(pCap,"Text","Start Capture","Position",[5,38,160,26],"BackgroundColor",GREEN,"FontColor",BLACK,"ButtonPushedFcn",@(~,~)onStart());
    stopBtn  = uibutton(pCap,"Text","Stop Capture","Position",[5,10,160,24],"BackgroundColor",BLACK,"FontColor",GREEN,"ButtonPushedFcn",@(~,~)onStop());

    %% ---- SINK ----
    sinkBtn = uibutton(ctrl,"Text","Sink to Disk","Position",[5,8,175,30], ...
        "BackgroundColor",BLACK,"FontColor",GREEN, ...
        "ButtonPushedFcn",@(~,~)onSinkToDisk());

    if isempty(px)
        [buildBtn.Enable, loadBtn.Enable, saveBtn.Enable, startBtn.Enable, stopBtn.Enable] = deal("off");
        sortStatus.Text = "no npxls proxy";
    end

    %% ---- callbacks ----
    function p = getPx()
        % Live lookup of the active npxls proxy — see the note at construction.
        p = [];
        try
            if isfield(nexObj.proxon.index_type2, 'npxls')
                p = nexObj.proxon.index_type2.npxls;
            end
        catch
        end
    end

    function onBuild()
        px = getPx();
        if isempty(px), uialert(nexObj.Figure.fh, "no npxls proxy", "Build failed"); return; end
        buildBtn.Enable = "off"; drawnow;
        try
            px.detectSequences(durField.Value);
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            uialert(nexObj.Figure.fh, e.message, "Build failed");
        end
        sortStatus.Text = sorterText(px);
        buildBtn.Enable = "on";
    end

    function onLoad()
        px = getPx();
        if isempty(px), uialert(nexObj.Figure.fh, "no npxls proxy", "Load failed"); return; end
        try
            px.loadSorter([]);
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            uialert(nexObj.Figure.fh, e.message, "Load failed");
        end
        sortStatus.Text = sorterText(px);
    end

    function onSave()
        px = getPx();
        if isempty(px), uialert(nexObj.Figure.fh, "no npxls proxy", "Save failed"); return; end
        try
            dest = px.saveSorter([]);
            uialert(nexObj.Figure.fh, "Saved to " + dest, "Sorter saved", "Icon", "success");
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            uialert(nexObj.Figure.fh, e.message, "Save failed");
        end
    end

    function onStart()
        px = getPx();
        if isempty(px), uialert(nexObj.Figure.fh, "no npxls proxy", "Capture failed"); return; end
        try
            px.startCapture(uint8(trialField.Value), []);   % same entry as the slrt relay
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            uialert(nexObj.Figure.fh, e.message, "Capture failed");
        end
    end

    function onStop()
        px = getPx();
        if isempty(px), uialert(nexObj.Figure.fh, "no npxls proxy", "Stop failed"); return; end
        try
            px.stopCapture([], []);
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            uialert(nexObj.Figure.fh, e.message, "Stop failed");
        end
    end

    function onSinkToDisk()
        DTS_inmem = nexon.console.BASE.DTS;

        if isempty(DTS_inmem) || ~istable(DTS_inmem) || height(DTS_inmem) == 0
            uialert(nexObj.Figure.fh, "No in-memory DTS to sink.", "Sink skipped"); return;
        end
        % Hybrid DTS: sink only the in-memory rows (h5_path=="") into the
        % existing store — nexDTS_appendRows extracts them. Refuse only when
        % there are no in-memory rows left to flush.
        nSink = height(DTS_inmem);
        if ismember('h5_path', DTS_inmem.Properties.VariableNames)
            nSink = nnz(strlength(string(DTS_inmem.h5_path)) == 0);
            if nSink == 0
                uialert(nexObj.Figure.fh, ...
                    "DTS is fully disk-backed — no in-memory rows to sink.", "Sink skipped");
                return;
            end
        end

        % Resolve DTS output path — prefer params, fall back to folder picker.
        dtsPath = [];
        try
            dtsPath = nexObj.nCORTEx.params.paths.Data.DTS.local;
        catch
        end
        if isempty(dtsPath)
            dtsPath = uigetdir(pwd, "Select DTS output folder");
            if isequal(dtsPath, 0), return; end   % user cancelled
        end

        sinkBtn.Enable = "off"; drawnow;
        try
            [h5File, manifest] = nexDTS_openOrCreate(dtsPath);
            % Data-loss guard: sinking a hybrid DTS relies on the existing
            % manifest being found so the already-disk rows are preserved in the
            % combine. Abort rather than drop them.
            if ismember('h5_path', DTS_inmem.Properties.VariableNames) && ...
                    (isempty(manifest) || ~istable(manifest))
                sinkBtn.Enable = "on";
                uialert(nexObj.Figure.fh, sprintf( ...
                    "Existing manifest not found at %s — aborting to avoid dropping disk rows.", ...
                    dtsPath), "Sink aborted");
                return;
            end
            manifest = nexDTS_appendRows(DTS_inmem, h5File, manifest, nexon, dtsPath);
            save(fullfile(dtsPath, 'nexDTS_manifest.mat'), 'manifest');
            nexon.console.BASE.DTS = manifest;
            try, nexon.console.BASE.updateControlPanel(); catch, end
            uialert(nexObj.Figure.fh, ...
                sprintf("Sinked %d rows to %s", nSink, dtsPath), ...
                "Sink complete", "Icon", "success");
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            uialert(nexObj.Figure.fh, e.message, "Sink failed");
        end
        sinkBtn.Enable = "on";
    end

    function onClose(fh)
        % The proxy outlives this panel (it lives on the proxon), so its sidecar
        % client + sorter cache would leak into the next panel. Tear them down so
        % a new panel opens fresh: QUIT the sidecar, drop rtSortClient, and clear
        % the sorter cache so Build rebuilds against a new warm sidecar.
        px = getPx();
        if ~isempty(px)
            try, px.rtSortClose(); catch, end   % sends QUIT, sets rtSortClient = []
            px.sorterReady = false;
            px.spkStatic   = [];
        end
        delete(fh);
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
