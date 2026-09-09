function P = nexPanel_ephysAtlas(nexon)
%NEXPANEL_EPHYSATLAS  Ephys Atlas management panel.
%
%   P = nexPanel_ephysAtlas(nexon)
%
%   nexon  live Nexon handle.  All subject paths, phase lists, and region
%          colors are resolved through nexon — no subjectDir argument needed.
%
%   Subject directory convention (matches nexInit_registry):
%     params.paths.projDir_local / "Experiments" / experiment / "Subjects" / subject
%
%   Forehead layout:
%     [◀] [▶]  Tab Label            [Subject dropdown]
%     ──────────────────────────────────────────────────
%     [                 active tab panel               ]
%
%   Tabs: 1=Reference  2=IBL Query  3=Posteriors  4=Sessions

    % ── Palette ──────────────────────────────────────────────────────────────
    c.BG  = [0.07 0.07 0.07];
    c.FG  = [0.92 0.92 0.92];
    c.DIM = [0.46 0.46 0.46];
    c.ACC = [0.28 0.52 0.83];
    c.SEP = [0.20 0.20 0.20];
    c.PNL = [0.10 0.10 0.10];

    FW = 960;  FH = 680;  FORE = 52;

    % ── Figure ───────────────────────────────────────────────────────────────
    fig = uifigure('Name','Ephys Atlas', ...
        'Position',        [80, 80, FW, FH], ...
        'Color',           c.BG, ...
        'Resize',          'off', ...
        'CloseRequestFcn', @(~,~) onClose(fig));

    % ── State ────────────────────────────────────────────────────────────────
    ud.nexon        = nexon;
    ud.atlasFile    = '';
    ud.currentTab   = 1;
    ud.tabNames     = {'Reference','IBL Query','Posteriors','Sessions'};
    ud.tabPanels    = {};
    ud.queryTimer   = [];
    ud.queryTmpFile = '';
    ud.queryReadPos = 0;
    ud.pythonExe    = expandHome('~/miniconda3/envs/nexus/bin/python');
    ud.scriptDir    = fileparts(mfilename('fullpath'));
    ud.c            = c;

    % Discover all subjects in registry → parallel subject/file arrays
    [ud.subjects, ud.atlasFiles] = findAtlasFiles(nexon);

    % ── Forehead ─────────────────────────────────────────────────────────────
    yF = FH - FORE;

    mkBtn = @(txt,x,cb) uibutton(fig,'Text',txt, ...
        'Position',[x,yF+11,30,30], ...
        'BackgroundColor',c.BG,'FontColor',c.FG,'FontSize',15, ...
        'ButtonPushedFcn',cb);
    ud.btnPrev = mkBtn('◀',12, @(~,~) switchTab(fig,-1));
    ud.btnNext = mkBtn('▶',48, @(~,~) switchTab(fig,+1));

    ud.lblTab = uilabel(fig,'Text','Reference', ...
        'Position',[88,yF+14,170,24], ...
        'FontColor',c.FG,'FontSize',12,'FontWeight','bold', ...
        'BackgroundColor',c.BG);

    % Subject dropdown (drives atlas file + color context)
    subjItems = subjectDDItems(ud.subjects, ud.atlasFiles);
    ud.ddSubject = uidropdown(fig, ...
        'Items',          subjItems, ...
        'Position',       [268,yF+14,528,24], ...
        'BackgroundColor',[0.12 0.12 0.12],'FontColor',c.FG, ...
        'ValueChangedFcn',@(dd,~) onSubjectChanged(fig,dd));

    uipanel(fig,'Position',[0,yF-1,FW,1], ...
        'BackgroundColor',c.SEP,'BorderType','none');

    % ── Tab panels ────────────────────────────────────────────────────────────
    tabPos = [0, 0, FW, yF-2];
    pnls   = {buildRefTab(fig,tabPos,c), buildIBLTab(fig,tabPos,c), ...
              buildPosTab(fig,tabPos,c), buildSesTab(fig,tabPos,c)};
    for k = 2:4, pnls{k}.Visible = 'off'; end
    ud.tabPanels = pnls;

    fig.UserData = ud;

    % Select current subject from nexon's controlPanel
    curSubj = currentSubject(nexon);
    if ~isempty(curSubj)
        dispItem = subjectLabel(curSubj, ud.atlasFiles, ud.subjects);
        if ismember(dispItem, subjItems)
            ud.ddSubject.Value = dispItem;
        end
    end
    if ~isempty(ud.atlasFiles)
        idx = find(strcmp(ud.subjects, curSubj), 1);
        if isempty(idx), idx = 1; end
        fig.UserData.atlasFile = ud.atlasFiles{idx};
        refreshRefSources(fig);
        populateTab(fig);
    end

    P.Figure = fig;
end


%% ════════════════════════════════════════════════════════════════════════════
%%  TAB BUILDERS
%% ════════════════════════════════════════════════════════════════════════════

function pn = buildRefTab(fig, pos, c)
    pn = tabPanel(fig, pos, c);
    W = pos(3);  H = pos(4);

    uilabel(pn,'Text','Source','Position',[12,H-38,54,22], ...
        'FontColor',c.DIM,'FontSize',10,'BackgroundColor',c.BG);
    uidropdown(pn,'Tag','refSrcDD','Items',{'Reference'}, ...
        'Position',[70,H-40,224,26], ...
        'BackgroundColor',[0.12 0.12 0.12],'FontColor',c.FG, ...
        'ValueChangedFcn',@(~,~) populateRefTable(fig));

    uibutton(pn,'Text','↺','Position',[302,H-40,38,26], ...
        'BackgroundColor',[0.13 0.13 0.13],'FontColor',c.FG,'FontSize',13, ...
        'Tooltip','Re-read atlas HDF5', ...
        'ButtonPushedFcn',@(~,~) refreshRefSources(fig));

    uilabel(pn,'Tag','refHint', ...
        'Text','Reference rows are editable.  Phase rows show posterior-weighted means from your recordings.', ...
        'Position',[350,H-38,570,20], ...
        'FontColor',c.DIM,'FontSize',9,'BackgroundColor',c.BG);

    cols = {'Region','ptd µ (ms)','ptd σ','fr µ (Hz)','fr σ','cv µ','cv σ','n','Source'};
    cw   = {80,84,60,84,60,60,56,44,88};
    tbl  = uitable(pn,'Tag','refTable', ...
        'Position',[12,12,W-24,H-56], ...
        'BackgroundColor',c.PNL,'ForegroundColor',c.FG, ...
        'ColumnName',cols,'ColumnWidth',cw, ...
        'ColumnEditable',[false true true true true true true false false], ...
        'RowName',{}, ...
        'CellEditCallback',@(tbl,ev) onRefCellEdit(fig,tbl,ev));
    styleTable(tbl);
end


function pn = buildIBLTab(fig, pos, c)
    pn = tabPanel(fig, pos, c);
    W = pos(3);  H = pos(4);
    LW = 262;  RX = LW+22;  RW = W-RX-12;

    uilabel(pn,'Text','Regions','Position',[12,H-28,LW,20], ...
        'FontColor',c.DIM,'FontSize',10,'BackgroundColor',c.BG);
    uilistbox(pn,'Tag','iblRegionList','Items',{}, ...
        'Position',[12,44,LW,H-74], ...
        'BackgroundColor',c.PNL,'FontColor',c.FG,'Multiselect','on');
    uibutton(pn,'Text','All','Position',[12,12,62,26], ...
        'BackgroundColor',[0.13 0.13 0.13],'FontColor',c.FG, ...
        'ButtonPushedFcn',@(~,~) setListAll(pn,'iblRegionList',true));
    uibutton(pn,'Text','None','Position',[80,12,62,26], ...
        'BackgroundColor',[0.13 0.13 0.13],'FontColor',c.FG, ...
        'ButtonPushedFcn',@(~,~) setListAll(pn,'iblRegionList',false));

    ctrlH = 162;  ctrlY = H - ctrlH - 10;

    uilabel(pn,'Text','Max sessions','Position',[RX,ctrlY+132,120,18], ...
        'FontColor',c.FG,'FontSize',10,'BackgroundColor',c.BG);
    uispinner(pn,'Tag','iblMaxSess','Value',80,'Step',10,'Limits',[1 999], ...
        'Position',[RX,ctrlY+110,100,26], ...
        'BackgroundColor',[0.12 0.12 0.12],'FontColor',c.FG);
    uicheckbox(pn,'Tag','iblSpontOnly','Text','Spontaneous sessions only', ...
        'Position',[RX,ctrlY+78,260,22],'FontColor',c.FG,'Value',false,'BackgroundColor',c.BG);
    uicheckbox(pn,'Tag','iblFallbackOnly','Text','Literature fallback only', ...
        'Position',[RX,ctrlY+52,260,22],'FontColor',c.FG,'Value',false,'BackgroundColor',c.BG);

    uibutton(pn,'Text','Run IBL Query', ...
        'Position',[RX,ctrlY+10,148,34], ...
        'BackgroundColor',c.ACC,'FontColor',[1 1 1],'FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~) runIBLQuery(fig));
    uibutton(pn,'Text','Stop', ...
        'Position',[RX+156,ctrlY+10,68,34], ...
        'BackgroundColor',[0.28 0.10 0.10],'FontColor',c.FG, ...
        'ButtonPushedFcn',@(~,~) stopIBLQuery(fig));

    outH = ctrlY - 16;
    uitextarea(pn,'Tag','iblOutput','Value',{'Ready.'}, ...
        'Position',[RX,12,RW,outH], ...
        'BackgroundColor',c.BG,'FontColor',c.FG, ...
        'FontSize',10,'FontName','Courier New', ...
        'Editable','off','Scrollable','on');
end


function pn = buildPosTab(fig, pos, c)
    pn = tabPanel(fig, pos, c);
    W = pos(3);  H = pos(4);
    LW = 200;

    uilabel(pn,'Text','Phase','Position',[12,H-36,50,22], ...
        'FontColor',c.FG,'FontSize',10,'BackgroundColor',c.BG);
    uidropdown(pn,'Tag','posPhaseDD','Items',{'(load atlas)'}, ...
        'Position',[66,H-38,200,26], ...
        'BackgroundColor',[0.12 0.12 0.12],'FontColor',c.FG, ...
        'ValueChangedFcn',@(dd,~) onPhaseSelected(fig,dd.Value,'pos'));
    uibutton(pn,'Text','Recompute','Position',[278,H-38,106,26], ...
        'BackgroundColor',[0.13 0.13 0.13],'FontColor',c.FG, ...
        'ButtonPushedFcn',@(~,~) recomputePosteriors(fig));
    uilabel(pn,'Tag','posInfo','Text','', ...
        'Position',[396,H-38,360,22], ...
        'FontColor',c.DIM,'FontSize',9,'BackgroundColor',c.BG);

    uilabel(pn,'Text','Channels','Position',[12,H-64,LW,20], ...
        'FontColor',c.DIM,'FontSize',10,'BackgroundColor',c.BG);
    uilistbox(pn,'Tag','posChanList','Items',{}, ...
        'Position',[12,12,LW,H-78], ...
        'BackgroundColor',c.PNL,'FontColor',c.FG, ...
        'ValueChangedFcn',@(lb,~) updatePosteriorChart(fig,lb.Value));

    ax = uiaxes(pn,'Position',[LW+28,12,W-LW-44,H-66]);
    ax.Tag = 'posAxes';
    ax.Color = c.PNL;  ax.XColor = c.FG;  ax.YColor = c.FG;
    ax.GridColor = c.DIM;  ax.FontSize = 9;  ax.Box = 'off';
    title(ax,'Select a channel','Color',c.FG,'FontSize',10);
    xlabel(ax,'P(region | channel)','Color',c.FG,'FontSize',9);
end


function pn = buildSesTab(fig, pos, c)
    pn = tabPanel(fig, pos, c);
    W = pos(3);  H = pos(4);

    uilabel(pn,'Text','Phase','Position',[12,H-36,50,22], ...
        'FontColor',c.FG,'FontSize',10,'BackgroundColor',c.BG);
    uidropdown(pn,'Tag','sesPhaseDD','Items',{'(load atlas)'}, ...
        'Position',[66,H-38,200,26], ...
        'BackgroundColor',[0.12 0.12 0.12],'FontColor',c.FG, ...
        'ValueChangedFcn',@(dd,~) onPhaseSelected(fig,dd.Value,'ses'));
    uilabel(pn,'Tag','sesInfo','Text','', ...
        'Position',[278,H-38,440,22], ...
        'FontColor',c.DIM,'FontSize',9,'BackgroundColor',c.BG);

    tbl = uitable(pn,'Tag','sesTable', ...
        'Position',[12,12,W-24,H-56], ...
        'BackgroundColor',c.PNL,'ForegroundColor',c.FG, ...
        'ColumnName',{'Session','Contributed','n sessions','Last Updated'}, ...
        'ColumnWidth',{240,80,90,180}, ...
        'ColumnEditable',[false false false false], ...
        'RowName',{});
    styleTable(tbl);
end


%% ════════════════════════════════════════════════════════════════════════════
%%  NAVIGATION
%% ════════════════════════════════════════════════════════════════════════════

function switchTab(fig, dir)
    ud = fig.UserData;
    n  = numel(ud.tabNames);
    ud.tabPanels{ud.currentTab}.Visible = 'off';
    ud.currentTab = mod(ud.currentTab - 1 + dir, n) + 1;
    ud.tabPanels{ud.currentTab}.Visible = 'on';
    ud.lblTab.Text = ud.tabNames{ud.currentTab};
    fig.UserData = ud;
    populateTab(fig);
end

function populateTab(fig)
    switch fig.UserData.currentTab
        case 1,  populateRefTable(fig);
        case 2,  populateIBLList(fig);
        case 3,  populatePosteriors(fig,'');
        case 4,  populateSessions(fig,'');
    end
end


%% ════════════════════════════════════════════════════════════════════════════
%%  SUBJECT DROPDOWN
%% ════════════════════════════════════════════════════════════════════════════

function onSubjectChanged(fig, dd)
    ud  = fig.UserData;
    % Strip the [!] marker if present
    raw = strrep(dd.Value, '[!] ', '');
    idx = find(strcmp(ud.subjects, raw), 1);
    if isempty(idx), return; end
    fig.UserData.atlasFile = ud.atlasFiles{idx};
    refreshRefSources(fig);
    populateTab(fig);
end


%% ════════════════════════════════════════════════════════════════════════════
%%  REFERENCE TAB
%% ════════════════════════════════════════════════════════════════════════════

function refreshRefSources(fig)
    ud = fig.UserData;
    if isempty(ud.atlasFile) || ~isfile(ud.atlasFile), return; end
    pn = ud.tabPanels{1};
    dd = findobj(pn,'Tag','refSrcDD');
    phases = atlasPhases(ud.atlasFile);
    items  = [{'Reference'}, phases(:)'];
    dd.Items = items;
    if ~ismember(dd.Value, items), dd.Value = 'Reference'; end
    populateRefTable(fig);
end

function populateRefTable(fig)
    ud  = fig.UserData;
    if isempty(ud.atlasFile) || ~isfile(ud.atlasFile), return; end
    pn  = ud.tabPanels{1};
    dd  = findobj(pn,'Tag','refSrcDD');
    tbl = findobj(pn,'Tag','refTable');
    src = dd.Value;

    if strcmp(src,'Reference')
        D = readReferenceData(ud.atlasFile);
        tbl.ColumnEditable = [false true true true true true true false false];
    else
        D = readPhaseFeatureData(ud.atlasFile, src);
        tbl.ColumnEditable = false(1,9);
    end
    tbl.Data = D;

    % Color-code rows by Allen CCF region color from nexon registry
    if ~isempty(D)
        regions = D(:,1);
        applyRegionColors(tbl, regions, ud.nexon);
    end
end

function D = readReferenceData(atlasFile)
    D = {};
    try, info = h5info(atlasFile,'/reference'); catch, return; end
    for gi = 1:numel(info.Groups)
        reg = strrep(info.Groups(gi).Name,'/reference/','');
        try
            mu  = double(h5read(atlasFile,['/reference/' reg '/mu']))';
            sig = double(h5read(atlasFile,['/reference/' reg '/sigma']))';
            n   = double(h5read(atlasFile,['/reference/' reg '/n_units']));
            try, src = char(h5read(atlasFile,['/reference/' reg '/source']));
            catch, src = 'IBL'; end
            D(end+1,:) = {reg, mu(1),sig(1), mu(2),sig(2), mu(3),sig(3), n(1), src}; %#ok<AGROW>
        catch
        end
    end
end

function D = readPhaseFeatureData(atlasFile, phase)
    D = {};
    base = ['/posteriors/' phase '/region_features'];
    try, info = h5info(atlasFile, base); catch, return; end
    for gi = 1:numel(info.Groups)
        reg = strrep(info.Groups(gi).Name,[base '/'],'');
        try
            mu  = double(h5read(atlasFile,[base '/' reg '/mu']))';
            sig = double(h5read(atlasFile,[base '/' reg '/sigma']))';
            n   = double(h5read(atlasFile,[base '/' reg '/n']));
            D(end+1,:) = {reg, mu(1),sig(1), mu(2),sig(2), mu(3),sig(3), n(1),'recorded'}; %#ok<AGROW>
        catch
        end
    end
end

function onRefCellEdit(fig, tbl, ev)
    ud = fig.UserData;
    if isempty(ud.atlasFile), return; end
    pn = ud.tabPanels{1};
    if ~strcmp(findobj(pn,'Tag','refSrcDD').Value,'Reference'), return; end

    feats   = {'','ptd_ms','ptd_ms','firing_rate','firing_rate','cv_isi','cv_isi','',''};
    ismuCol = [false true false true false true false false false];
    col     = ev.Indices(2);
    if col < 2 || col > 7, return; end
    newVal = ev.NewData;
    if ~isnumeric(newVal) || ~isfinite(newVal)
        tbl.Data{ev.Indices(1), col} = ev.PreviousData; return;
    end
    region  = tbl.Data{ev.Indices(1), 1};
    feature = feats{col};
    try
        mu_vec  = double(h5read(ud.atlasFile,['/reference/' region '/mu']));
        sig_vec = double(h5read(ud.atlasFile,['/reference/' region '/sigma']));
    catch, return; end
    featOrder = {'ptd_ms','firing_rate','cv_isi'};
    fi = find(strcmp(featOrder, feature), 1);
    if ismuCol(col), mu_vec(fi) = newVal; else, sig_vec(fi) = newVal; end

    py  = ud.pythonExe;
    sc  = fullfile(ud.scriptDir,'nexAtlas_setReference.py');
    cmd = sprintf('"%s" "%s" "%s" --region %s --feature %s --mu %.6f --sigma %.6f', ...
        py, sc, ud.atlasFile, region, feature, mu_vec(fi), sig_vec(fi));
    system(cmd);
end


%% ════════════════════════════════════════════════════════════════════════════
%%  REGION COLOR STYLING
%% ════════════════════════════════════════════════════════════════════════════

function applyRegionColors(tbl, regions, nexon)
    removeStyle(tbl);
    if isempty(regions) || isempty(nexon), return; end
    try
        [cmap, matched] = nex_axisColorFromRegistry(nexon, 'map', string(regions));
        if ~matched, return; end
        for ri = 1:numel(regions)
            bg  = cmap(ri,:);
            lum = 0.299*bg(1) + 0.587*bg(2) + 0.114*bg(3);
            if lum > 0.45, fg = [0.05 0.05 0.05]; else, fg = [0.95 0.95 0.95]; end
            addStyle(tbl, uistyle('BackgroundColor',bg,'FontColor',fg), 'row', ri);
        end
    catch
    end
end


%% ════════════════════════════════════════════════════════════════════════════
%%  IBL QUERY TAB
%% ════════════════════════════════════════════════════════════════════════════

function populateIBLList(fig)
    ud = fig.UserData;
    if isempty(ud.atlasFile) || ~isfile(ud.atlasFile), return; end
    lb = findobj(ud.tabPanels{2},'Tag','iblRegionList');
    try
        lb.Items = cellstr(string(h5read(ud.atlasFile,'/prior/region_acronyms')));
    catch
        lb.Items = {};
    end
end

function setListAll(pn, tag, allOn)
    lb = findobj(pn,'Tag',tag);
    if allOn, lb.Value = lb.Items; else, lb.Value = {}; end
end

function runIBLQuery(fig)
    ud  = fig.UserData;
    if isempty(ud.atlasFile), iblLog(fig,'  No atlas file selected.'); return; end
    pn  = ud.tabPanels{2};
    lb  = findobj(pn,'Tag','iblRegionList');
    sp  = findobj(pn,'Tag','iblMaxSess');
    cb1 = findobj(pn,'Tag','iblSpontOnly');
    cb2 = findobj(pn,'Tag','iblFallbackOnly');
    ta  = findobj(pn,'Tag','iblOutput');

    regions = lb.Value;
    if isempty(regions), iblLog(fig,'  Select at least one region.'); return; end

    stopIBLQuery(fig);

    tmpFile = [tempname '.txt'];
    ud.queryTmpFile = tmpFile;
    ud.queryReadPos = 0;
    fig.UserData    = ud;

    flags = '';
    if cb1.Value, flags = [flags ' --spontaneous_only']; end
    if cb2.Value, flags = [flags ' --fallback_only'];    end

    py  = ud.pythonExe;
    sc  = fullfile(ud.scriptDir,'nexAtlas_queryIBL.py');
    cmd = sprintf('"%s" "%s" "%s" --regions %s --max_sessions %d%s > "%s" 2>&1 &', ...
        py, sc, ud.atlasFile, strjoin(regions,' '), sp.Value, flags, tmpFile);

    ta.Value = {sprintf('[%s] Starting IBL query...', datestr(now,'HH:MM:SS'))};
    system(cmd);

    t = timer('Name','IBLPoll','Period',2,'ExecutionMode','fixedRate', ...
        'TimerFcn',@(~,~) pollIBLOutput(fig));
    ud = fig.UserData;
    ud.queryTimer = t;
    fig.UserData  = ud;
    start(t);
end

function pollIBLOutput(fig)
    ud  = fig.UserData;
    ta  = findobj(ud.tabPanels{2},'Tag','iblOutput');
    if isempty(ud.queryTmpFile) || ~isfile(ud.queryTmpFile), return; end

    fid = fopen(ud.queryTmpFile,'r');
    if fid < 0, return; end
    fseek(fid, ud.queryReadPos, 'bof');
    newText = fread(fid, Inf, '*char')';
    ud.queryReadPos = ftell(fid);
    fclose(fid);

    if ~isempty(strtrim(newText))
        lines    = strsplit(newText, newline);
        ta.Value = [ta.Value(:)', lines(:)'];
        try, scroll(ta,'bottom'); catch, end
    end
    fig.UserData = ud;

    if contains(fileread(ud.queryTmpFile), '[nexAtlas_queryIBL] done')
        stopIBLQuery(fig);
        iblLog(fig, sprintf('[%s] Done.', datestr(now,'HH:MM:SS')));
        refreshRefSources(fig);
    end
end

function stopIBLQuery(fig)
    ud = fig.UserData;
    if ~isempty(ud.queryTimer) && isvalid(ud.queryTimer)
        stop(ud.queryTimer);  delete(ud.queryTimer);
    end
    ud.queryTimer = [];
    fig.UserData  = ud;
end

function iblLog(fig, msg)
    ta = findobj(fig.UserData.tabPanels{2},'Tag','iblOutput');
    ta.Value = [ta.Value(:)', {msg}];
end


%% ════════════════════════════════════════════════════════════════════════════
%%  POSTERIORS TAB
%% ════════════════════════════════════════════════════════════════════════════

function populatePosteriors(fig, phaseIn)
    ud = fig.UserData;
    if isempty(ud.atlasFile) || ~isfile(ud.atlasFile), return; end
    pn  = ud.tabPanels{3};
    dd  = findobj(pn,'Tag','posPhaseDD');
    lb  = findobj(pn,'Tag','posChanList');

    phases = atlasPhases(ud.atlasFile);
    if isempty(phases), dd.Items = {'(none)'}; return; end
    dd.Items = phases;
    if ~isempty(phaseIn) && ismember(phaseIn,phases), dd.Value = phaseIn; end
    phase = dd.Value;

    try
        ch_idx = double(h5read(ud.atlasFile,'/prior/channel_indices'));
        lb.Items = arrayfun(@(c) sprintf('ch %d',c), ch_idx,'UniformOutput',false);
    catch
        lb.Items = {};
    end
    updatePhaseInfo(pn, ud.atlasFile, phase, 'posInfo');
end

function updatePosteriorChart(fig, chanVal)
    ud = fig.UserData;
    if isempty(ud.atlasFile) || ~isfile(ud.atlasFile) || isempty(chanVal), return; end
    pn    = ud.tabPanels{3};
    phase = findobj(pn,'Tag','posPhaseDD').Value;
    ax    = findobj(pn,'Tag','posAxes');
    chanN = sscanf(chanVal,'ch %d');
    if isempty(chanN), return; end

    try
        ch_all = double(h5read(ud.atlasFile,'/prior/channel_indices'));
        row    = find(ch_all == chanN, 1);
        if isempty(row), return; end
        post = double(h5read(ud.atlasFile,['/posteriors/' phase '/posterior']));
        p_row = post(row,:);
        regs  = string(h5read(ud.atlasFile,'/prior/region_acronyms'));
    catch, return; end

    [p_s, si] = sort(p_row,'descend');
    N = min(14, numel(si));
    c = ud.c;

    % Bar colors from registry — fall back to accent
    topRegs = cellstr(regs(si(1:N)));
    try
        [barClrs, matched] = nex_axisColorFromRegistry(ud.nexon, 'map', string(topRegs));
        if ~matched, barClrs = repmat(c.ACC, N, 1); end
    catch
        barClrs = repmat(c.ACC, N, 1);
    end

    cla(ax);
    hold(ax,'on');
    for bi = 1:N
        barh(ax, bi, p_s(bi), 'FaceColor', barClrs(bi,:), 'EdgeColor','none');
    end
    hold(ax,'off');
    ax.YTick = 1:N;  ax.YTickLabel = topRegs;  ax.YDir = 'reverse';
    ax.Color = c.PNL;  ax.XColor = c.FG;  ax.YColor = c.FG;
    ax.GridColor = c.DIM;  ax.XGrid = 'on';  ax.Box = 'off';
    title(ax, sprintf('ch %d — %s', chanN, phase),'Color',c.FG,'FontSize',10);
    xlabel(ax,'P(region | channel)','Color',c.DIM,'FontSize',9);
end

function onPhaseSelected(fig, phase, which)
    switch which
        case 'pos', populatePosteriors(fig, phase);
        case 'ses', populateSessions(fig, phase);
    end
end

function recomputePosteriors(fig)
    ud      = fig.UserData;
    infoLbl = findobj(ud.tabPanels{3},'Tag','posInfo');
    if isempty(ud.atlasFile), return; end
    if exist('nexAtlas_recomputePosteriors','file')
        infoLbl.Text = 'Recomputing...'; drawnow;
        nexAtlas_recomputePosteriors(ud.atlasFile);
        populatePosteriors(fig,'');
    else
        infoLbl.Text = 'nexAtlas_recomputePosteriors not found on path.';
    end
end


%% ════════════════════════════════════════════════════════════════════════════
%%  SESSIONS TAB
%% ════════════════════════════════════════════════════════════════════════════

function populateSessions(fig, phaseIn)
    ud  = fig.UserData;
    if isempty(ud.atlasFile) || ~isfile(ud.atlasFile), return; end
    pn  = ud.tabPanels{4};
    dd  = findobj(pn,'Tag','sesPhaseDD');
    tbl = findobj(pn,'Tag','sesTable');

    phases = atlasPhases(ud.atlasFile);
    if isempty(phases), dd.Items = {'(none)'}; tbl.Data = {}; return; end
    dd.Items = phases;
    if ~isempty(phaseIn) && ismember(phaseIn,phases), dd.Value = phaseIn; end
    phase = dd.Value;
    updatePhaseInfo(pn, ud.atlasFile, phase, 'sesInfo');

    try
        n_sess = double(h5read(ud.atlasFile,['/posteriors/' phase '/n_sessions']));
        try, lu = char(h5read(ud.atlasFile,['/posteriors/' phase '/last_updated']));
        catch, lu = '–'; end
    catch
        n_sess = 0; lu = '–';
    end

    D = {};
    try
        sinfo = h5info(ud.atlasFile,'/sessions');
        for gi = 1:numel(sinfo.Groups)
            lbl = strrep(sinfo.Groups(gi).Name,'/sessions/','');
            try, contrib = logical(h5read(ud.atlasFile,['/sessions/' lbl '/contributed']));
            catch, contrib = false; end
            D(end+1,:) = {lbl, contrib, n_sess, lu}; %#ok<AGROW>
        end
    catch
    end
    tbl.Data = D;
end


%% ════════════════════════════════════════════════════════════════════════════
%%  SHARED HELPERS
%% ════════════════════════════════════════════════════════════════════════════

function pn = tabPanel(fig, pos, c)
    pn = uipanel(fig,'Position',pos,'BackgroundColor',c.BG,'BorderType','none');
end

function styleTable(tbl)
    try, tbl.RowStriping = 'off'; catch, end
end

function updatePhaseInfo(pn, atlasFile, phase, tag)
    lbl = findobj(pn,'Tag',tag);
    if isempty(lbl), return; end
    try
        n  = double(h5read(atlasFile,['/posteriors/' phase '/n_sessions']));
        try, lu = char(h5read(atlasFile,['/posteriors/' phase '/last_updated']));
        catch, lu = '–'; end
        lbl.Text = sprintf('n_sessions=%d   updated: %s', n, lu);
    catch
        lbl.Text = '';
    end
end

function phases = atlasPhases(atlasFile)
    phases = {};
    try
        info   = h5info(atlasFile,'/posteriors');
        phases = cellfun(@(g) strrep(g.Name,'/posteriors/',''), ...
            num2cell(info.Groups),'UniformOutput',false);
    catch
    end
end

function [subjects, files] = findAtlasFiles(nexon)
    subjects = {};  files = {};
    try
        params  = nexon.console.BASE.params;
        allSubjs = nexon.console.BASE.registry.categories.subj;
        for i = 1:numel(allSubjs)
            subj = char(allSubjs(i));
            for base = {params.paths.projDir_local, params.paths.projDir_cloud}
                sdir = fullfile(base{1},'Experiments', ...
                    params.extractCfg.experiment,'Subjects',subj);
                h5 = fullfile(sdir,'npxls','ephys_atlas.h5');
                if isfile(h5) && ~ismember(h5,files)
                    subjects{end+1} = subj; %#ok<AGROW>
                    files{end+1}    = h5;   %#ok<AGROW>
                    break;
                end
            end
        end
    catch
    end
end

function subj = currentSubject(nexon)
    subj = '';
    try
        avgSel  = nexon.console.BASE.controlPanel.averagingSelection;
        subjAll = avgSel.selKeys.subj;
        subjIdx = avgSel.selections.subj;
        subj    = char(string(subjAll(subjIdx(1))));
    catch
        try
            subj = char(nexon.console.BASE.router.entryParams.subject);
        catch
        end
    end
end

function items = subjectDDItems(subjects, files)
    if isempty(subjects), items = {'(none)'}; return; end
    items = cell(size(subjects));
    for i = 1:numel(subjects)
        if isfile(files{i}), items{i} = subjects{i};
        else,                 items{i} = ['[!] ' subjects{i}];
        end
    end
end

function lbl = subjectLabel(subj, files, subjects)
    idx = find(strcmp(subjects, subj), 1);
    if isempty(idx), lbl = subj; return; end
    if isfile(files{idx}), lbl = subj;
    else,                   lbl = ['[!] ' subj];
    end
end

function p = expandHome(path)
    try,  home = char(java.lang.System.getProperty('user.home'));
    catch, home = getenv('HOME'); end
    p = strrep(path,'~',home);
end

function onClose(fig)
    stopIBLQuery(fig);
    delete(fig);
end
