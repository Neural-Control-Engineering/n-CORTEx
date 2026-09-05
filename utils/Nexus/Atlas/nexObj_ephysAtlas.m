classdef nexObj_ephysAtlas < nexObject
%NEXOBJ_EPHYSATLAS  Ephys Atlas panel — nexObject subclass.
%
%   Holds all atlas state and logic.  nexFigure_ephysAtlas(obj) builds the
%   figure geometry and wires callbacks to this object's public methods.
%
%   Usage:
%     nexon.console.ATLAS = nexObj_ephysAtlas(nexon);
%     nexon.console.ATLAS.raise();
%     nexon.console.ATLAS.runQuery();
%     nexon.console.ATLAS.recompute();

    properties
        classID = "atlas"
    end

    properties (GetAccess = public, SetAccess = private)
        pal     % color palette struct — read by nexFigure_ephysAtlas at build time
    end

    properties (Access = private)
        atlasFile    = ''
        atlasSubject = ''
        subjects     = {}
        atlasFiles   = {}
        currentTab   = 1
        tabNames     = {'Reference','IBL Query','Posteriors','Sessions'}
        queryTimer   = []
        queryTmpFile = ''
        queryReadPos = 0
        pythonExe    = ''
        scriptDir    = ''
    end

    % ── Standard nexObject interface ──────────────────────────────────────────
    methods

        function obj = nexObj_ephysAtlas(nexon)
            obj = obj@nexObject(nexon, [], [], 'Ephys Atlas');
            obj.classID   = "atlas";
            obj.pythonExe = obj.expandHome_('~/miniconda3/envs/nexus/bin/python');
            obj.scriptDir = fileparts(mfilename('fullpath'));
            [obj.subjects, obj.atlasFiles] = obj.findAtlasFiles_();
            obj.buildFigure_();
            try
                lf = nexon.UserData.launchedFigures;
                nexon.UserData.launchedFigures = [lf, {obj}];
            catch
                try, nexon.UserData.launchedFigures = {obj}; catch, end
            end
        end

        function updateScope(obj)
            if ~obj.figAlive_(), return; end
            newSubj = obj.getSubject_();
            if strcmp(newSubj, obj.atlasSubject), return; end
            idx = find(strcmp(obj.subjects, newSubj), 1);
            if isempty(idx), return; end
            obj.atlasFile    = obj.atlasFiles{idx};
            obj.atlasSubject = newSubj;
            obj.Figure.subjLbl.Text = newSubj;
            obj.refreshRefSources();
            obj.populateTab_();
        end

        function visualize(obj)
            if obj.figAlive_(), obj.populateTab_(); end
        end

        function raise(obj)
            if ~obj.figAlive_(), obj.buildFigure_();
            else, figure(obj.Figure.fh); end
        end

        function runQuery(obj)
            if obj.figAlive_(), obj.runIBLQuery(); end
        end

        function recompute(obj)
            if obj.figAlive_(), obj.recomputePosteriors(); end
        end

        function closeFcn(obj)
            obj.stopIBLQuery();
            obj.closeFcn@nexObject();
        end

    end

    % ── Public methods — called from nexFigure callbacks ──────────────────────
    methods

        function switchTab(obj, dir)
            n = numel(obj.tabNames);
            obj.Figure.tabPanels{obj.currentTab}.Visible = 'off';
            obj.currentTab = mod(obj.currentTab - 1 + dir, n) + 1;
            obj.Figure.tabPanels{obj.currentTab}.Visible = 'on';
            obj.Figure.lblTab.Text = obj.tabNames{obj.currentTab};
            obj.populateTab_();
        end

        % ── Reference tab ─────────────────────────────────────────────────

        function refreshRefSources(obj)
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile), return; end
            pn = obj.Figure.tabPanels{1};
            dd = findobj(pn,'Tag','refSrcDD');
            phases = obj.atlasPhases_();
            items  = [{'Reference'}, phases(:)'];
            dd.Items = items;
            if ~ismember(dd.Value, items), dd.Value = 'Reference'; end
            obj.populateRefTable();
        end

        function populateRefTable(obj)
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile), return; end
            pn  = obj.Figure.tabPanels{1};
            dd  = findobj(pn,'Tag','refSrcDD');
            tbl = findobj(pn,'Tag','refTable');
            src = dd.Value;
            if strcmp(src,'Reference')
                D = obj.readReferenceData_();
                tbl.ColumnEditable = [false true true true true true true false false];
            else
                D = obj.readPhaseFeatureData_(src);
                tbl.ColumnEditable = false(1,9);
            end
            tbl.Data = D;
            if ~isempty(D)
                obj.applyRegionColors_(tbl, D(:,1));
            end
        end

        function onRefCellEdit(obj, tbl, ev)
            if isempty(obj.atlasFile), return; end
            pn = obj.Figure.tabPanels{1};
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
                mu_vec  = double(h5read(obj.atlasFile,['/reference/' region '/mu']));
                sig_vec = double(h5read(obj.atlasFile,['/reference/' region '/sigma']));
            catch, return; end
            fi = find(strcmp({'ptd_ms','firing_rate','cv_isi'}, feature), 1);
            if ismuCol(col), mu_vec(fi) = newVal; else, sig_vec(fi) = newVal; end
            cmd = sprintf('"%s" "%s" "%s" --region %s --feature %s --mu %.6f --sigma %.6f', ...
                obj.pythonExe, fullfile(obj.scriptDir,'nexAtlas_setReference.py'), ...
                obj.atlasFile, region, feature, mu_vec(fi), sig_vec(fi));
            system(cmd);
        end

        % ── IBL Query tab ─────────────────────────────────────────────────

        function runIBLQuery(obj)
            if isempty(obj.atlasFile)
                obj.iblLog_('  No atlas file selected.'); return;
            end
            pn  = obj.Figure.tabPanels{2};
            lb  = findobj(pn,'Tag','iblRegionList');
            sp  = findobj(pn,'Tag','iblMaxSess');
            cb1 = findobj(pn,'Tag','iblSpontOnly');
            cb2 = findobj(pn,'Tag','iblFallbackOnly');
            ta  = findobj(pn,'Tag','iblOutput');
            regions = lb.Value;
            if isempty(regions), obj.iblLog_('  Select at least one region.'); return; end
            obj.stopIBLQuery();
            tmpFile = [tempname '.txt'];
            obj.queryTmpFile = tmpFile;
            obj.queryReadPos = 0;
            flags = '';
            if cb1.Value, flags = [flags ' --spontaneous_only']; end
            if cb2.Value, flags = [flags ' --fallback_only'];    end
            cmd = sprintf('"%s" "%s" "%s" --regions %s --max_sessions %d%s > "%s" 2>&1 &', ...
                obj.pythonExe, fullfile(obj.scriptDir,'nexAtlas_queryIBL.py'), ...
                obj.atlasFile, strjoin(regions,' '), sp.Value, flags, tmpFile);
            ta.Value = {sprintf('[%s] Starting IBL query...', datestr(now,'HH:MM:SS'))};
            system(cmd);
            t = timer('Name','IBLPoll','Period',2,'ExecutionMode','fixedRate', ...
                'TimerFcn',@(~,~) obj.pollIBLOutput_());
            obj.queryTimer = t;
            start(t);
        end

        function stopIBLQuery(obj)
            if ~isempty(obj.queryTimer) && isvalid(obj.queryTimer)
                stop(obj.queryTimer);  delete(obj.queryTimer);
            end
            obj.queryTimer = [];
        end

        % ── Posteriors tab ────────────────────────────────────────────────

        function populatePosteriors(obj, phaseIn)
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile), return; end
            pn = obj.Figure.tabPanels{3};
            dd = findobj(pn,'Tag','posPhaseDD');
            lb = findobj(pn,'Tag','posChanList');
            phases = obj.atlasPhases_();
            if isempty(phases), dd.Items = {'(none)'}; return; end
            dd.Items = phases;
            if ~isempty(phaseIn) && ismember(phaseIn,phases), dd.Value = phaseIn; end
            phase = dd.Value;
            try
                ch_idx = double(h5read(obj.atlasFile,'/prior/channel_indices'));
                lb.Items = arrayfun(@(c) sprintf('ch %d',c), ch_idx,'UniformOutput',false);
            catch
                lb.Items = {};
            end
            obj.updatePhaseInfo_(pn, phase, 'posInfo');
        end

        function updatePosteriorChart(obj, chanVal)
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile) || isempty(chanVal), return; end
            pn    = obj.Figure.tabPanels{3};
            phase = findobj(pn,'Tag','posPhaseDD').Value;
            ax    = findobj(pn,'Tag','posAxes');
            chanN = sscanf(chanVal,'ch %d');
            if isempty(chanN), return; end
            try
                ch_all = double(h5read(obj.atlasFile,'/prior/channel_indices'));
                row    = find(ch_all == chanN, 1);
                if isempty(row), return; end
                post  = double(h5read(obj.atlasFile,['/posteriors/' phase '/posterior']));
                p_row = post(row,:);
                regs  = string(h5read(obj.atlasFile,'/prior/region_acronyms'));
            catch, return; end
            [p_s, si] = sort(p_row,'descend');
            N = min(14, numel(si));
            c = obj.pal;
            topRegs = cellstr(regs(si(1:N)));
            try
                [barClrs, matched] = nex_axisColorFromRegistry(obj.nexon, 'map', string(topRegs));
                if ~matched, barClrs = repmat(c.ACC, N, 1); end
            catch
                barClrs = repmat(c.ACC, N, 1);
            end
            cla(ax);  hold(ax,'on');
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

        function recomputePosteriors(obj)
            infoLbl = findobj(obj.Figure.tabPanels{3},'Tag','posInfo');
            if isempty(obj.atlasFile), return; end
            if exist('nexAtlas_recomputePosteriors','file')
                infoLbl.Text = 'Recomputing...'; drawnow;
                nexAtlas_recomputePosteriors(obj.atlasFile);
                obj.populatePosteriors('');
            else
                infoLbl.Text = 'nexAtlas_recomputePosteriors not found on path.';
            end
        end

        % ── Sessions tab ──────────────────────────────────────────────────

        function populateSessions(obj, phaseIn)
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile), return; end
            pn  = obj.Figure.tabPanels{4};
            dd  = findobj(pn,'Tag','sesPhaseDD');
            tbl = findobj(pn,'Tag','sesTable');
            phases = obj.atlasPhases_();
            if isempty(phases), dd.Items = {'(none)'}; tbl.Data = {}; return; end
            dd.Items = phases;
            if ~isempty(phaseIn) && ismember(phaseIn,phases), dd.Value = phaseIn; end
            phase = dd.Value;
            obj.updatePhaseInfo_(pn, phase, 'sesInfo');
            try
                n_sess = double(h5read(obj.atlasFile,['/posteriors/' phase '/n_sessions']));
                try, lu = char(h5read(obj.atlasFile,['/posteriors/' phase '/last_updated']));
                catch, lu = '–'; end
            catch
                n_sess = 0; lu = '–';
            end
            D = {};
            try
                sinfo = h5info(obj.atlasFile,'/sessions');
                for gi = 1:numel(sinfo.Groups)
                    lbl = strrep(sinfo.Groups(gi).Name,'/sessions/','');
                    try, contrib = logical(h5read(obj.atlasFile,['/sessions/' lbl '/contributed']));
                    catch, contrib = false; end
                    D(end+1,:) = {lbl, contrib, n_sess, lu}; %#ok<AGROW>
                end
            catch
            end
            tbl.Data = D;
        end

    end

    % ── Private helpers ───────────────────────────────────────────────────────
    methods (Access = private)

        function buildFigure_(obj)
            obj.pal = struct('BG',[0.07 0.07 0.07],'FG',[0.92 0.92 0.92], ...
                             'DIM',[0.46 0.46 0.46],'ACC',[0.28 0.52 0.83], ...
                             'SEP',[0.20 0.20 0.20],'PNL',[0.10 0.10 0.10]);
            fig = nexFigure_ephysAtlas(obj);
            obj.Figure.fh = fig;
            obj.applyHeadline();
            % Seed with current subject
            subj = obj.getSubject_();
            idx  = find(strcmp(obj.subjects, subj), 1);
            if isempty(idx) && ~isempty(obj.subjects), idx = 1; end
            if ~isempty(idx)
                obj.atlasFile    = obj.atlasFiles{idx};
                obj.atlasSubject = obj.subjects{idx};
                obj.Figure.subjLbl.Text = obj.subjects{idx};
            end
            if ~isempty(obj.atlasFile)
                obj.refreshRefSources();
                obj.populateTab_();
            end
        end

        function alive = figAlive_(obj)
            alive = isfield(obj.Figure,'fh') && ...
                    ~isempty(obj.Figure.fh)  && ...
                    isvalid(obj.Figure.fh);
        end

        function populateTab_(obj)
            switch obj.currentTab
                case 1,  obj.populateRefTable();
                case 2,  obj.populateIBLList_();
                case 3,  obj.populatePosteriors('');
                case 4,  obj.populateSessions('');
            end
        end

        function populateIBLList_(obj)
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile), return; end
            lb = findobj(obj.Figure.tabPanels{2},'Tag','iblRegionList');
            try
                lb.Items = cellstr(string(h5read(obj.atlasFile,'/prior/region_acronyms')));
            catch
                lb.Items = {};
            end
        end

        function pollIBLOutput_(obj)
            ta = findobj(obj.Figure.tabPanels{2},'Tag','iblOutput');
            if isempty(obj.queryTmpFile) || ~isfile(obj.queryTmpFile), return; end
            fid = fopen(obj.queryTmpFile,'r');
            if fid < 0, return; end
            fseek(fid, obj.queryReadPos, 'bof');
            newText = fread(fid, Inf, '*char')';
            obj.queryReadPos = ftell(fid);
            fclose(fid);
            if ~isempty(strtrim(newText))
                lines    = strsplit(newText, newline);
                ta.Value = [ta.Value(:)', lines(:)'];
                try, scroll(ta,'bottom'); catch, end
            end
            if contains(fileread(obj.queryTmpFile), '[nexAtlas_queryIBL] done')
                obj.stopIBLQuery();
                obj.iblLog_(sprintf('[%s] Done.', datestr(now,'HH:MM:SS')));
                obj.refreshRefSources();
            end
        end

        function iblLog_(obj, msg)
            ta = findobj(obj.Figure.tabPanels{2},'Tag','iblOutput');
            ta.Value = [ta.Value(:)', {msg}];
        end

        function applyRegionColors_(obj, tbl, regions)
            removeStyle(tbl);
            if isempty(regions), return; end
            try
                [cmap, matched] = nex_axisColorFromRegistry(obj.nexon, 'map', string(regions));
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

        function updatePhaseInfo_(obj, pn, phase, tag)
            lbl = findobj(pn,'Tag',tag);
            if isempty(lbl), return; end
            try
                n  = double(h5read(obj.atlasFile,['/posteriors/' phase '/n_sessions']));
                try, lu = char(h5read(obj.atlasFile,['/posteriors/' phase '/last_updated']));
                catch, lu = '–'; end
                lbl.Text = sprintf('n_sessions=%d   updated: %s', n, lu);
            catch
                lbl.Text = '';
            end
        end

        function phases = atlasPhases_(obj)
            phases = {};
            try
                info   = h5info(obj.atlasFile,'/posteriors');
                phases = cellfun(@(g) strrep(g.Name,'/posteriors/',''), ...
                    num2cell(info.Groups),'UniformOutput',false);
            catch
            end
        end

        function D = readReferenceData_(obj)
            D = {};
            try, info = h5info(obj.atlasFile,'/reference'); catch, return; end
            for gi = 1:numel(info.Groups)
                reg = strrep(info.Groups(gi).Name,'/reference/','');
                try
                    mu  = double(h5read(obj.atlasFile,['/reference/' reg '/mu']))';
                    sig = double(h5read(obj.atlasFile,['/reference/' reg '/sigma']))';
                    n   = double(h5read(obj.atlasFile,['/reference/' reg '/n_units']));
                    try, src = char(h5read(obj.atlasFile,['/reference/' reg '/source']));
                    catch, src = 'IBL'; end
                    D(end+1,:) = {reg, mu(1),sig(1), mu(2),sig(2), mu(3),sig(3), n(1), src}; %#ok<AGROW>
                catch
                end
            end
        end

        function D = readPhaseFeatureData_(obj, phase)
            D = {};
            base = ['/posteriors/' phase '/region_features'];
            try, info = h5info(obj.atlasFile, base); catch, return; end
            for gi = 1:numel(info.Groups)
                reg = strrep(info.Groups(gi).Name,[base '/'],'');
                try
                    mu  = double(h5read(obj.atlasFile,[base '/' reg '/mu']))';
                    sig = double(h5read(obj.atlasFile,[base '/' reg '/sigma']))';
                    n   = double(h5read(obj.atlasFile,[base '/' reg '/n']));
                    D(end+1,:) = {reg, mu(1),sig(1), mu(2),sig(2), mu(3),sig(3), n(1),'recorded'}; %#ok<AGROW>
                catch
                end
            end
        end

        function [subjects, files] = findAtlasFiles_(obj)
            subjects = {};  files = {};
            try
                params   = obj.nexon.console.BASE.params;
                allSubjs = obj.nexon.console.BASE.registry.categories.subj;
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

        function subj = getSubject_(obj)
            subj = '';
            try
                avgSel  = obj.nexon.console.BASE.controlPanel.averagingSelection;
                subjAll = avgSel.selKeys.subj;
                subjIdx = avgSel.selections.subj;
                subj    = char(string(subjAll(subjIdx(1))));
            catch
                try
                    subj = char(obj.nexon.console.BASE.router.entryParams.subject);
                catch
                end
            end
        end

        function p = expandHome_(~, path)
            try,  home = char(java.lang.System.getProperty('user.home'));
            catch, home = getenv('HOME'); end
            p = strrep(path,'~',home);
        end

    end
end
