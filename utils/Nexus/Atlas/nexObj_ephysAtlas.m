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

    properties (GetAccess = public, SetAccess = private)
        pal     % color palette struct — read by nexFigure_ephysAtlas at build time
    end

    properties (Access = private)
        atlasFile    = ''
        atlasSubject = ''
        currentTab   = 1
        tabNames     = {'Reference','IBL Query','Posteriors','Sessions','Units','Map'}
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
            h5 = obj.findAtlasFile_(newSubj);
            if isempty(h5), return; end
            obj.atlasFile    = h5;
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
            obj.padTableRows_(tbl);
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
            if ~isnumeric(newVal) || isinf(newVal)
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
            cmd = sprintf('"%s" "%s" "%s" --region %s --feature %s --mu %.6f --sigma %.6f --source Manual', ...
                obj.pythonExe, fullfile(obj.scriptDir,'nexAtlas_setReference.py'), ...
                obj.atlasFile, region, feature, mu_vec(fi), sig_vec(fi));
            system(cmd);
            tbl.Data{ev.Indices(1), 9} = 'Manual';
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
            cmd = sprintf('"%s" -u "%s" "%s" --regions %s --max_sessions %d%s > "%s" 2>&1 &', ...
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
            if ~isempty(lb.Value)
                obj.updatePosteriorChart(lb.Value);
            end
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
            ax.Color = c.BG;  ax.XColor = c.FG;  ax.YColor = c.FG;
            ax.GridColor = c.DIM;  ax.XGrid = 'on';  ax.Box = 'off';
            title(ax, sprintf('ch %d — %s', chanN, phase),'Color',c.FG,'FontSize',10);
            xlabel(ax,'P(region | channel)','Color',c.DIM,'FontSize',9);
        end

        function recomputePosteriors(obj)
            infoLbl = findobj(obj.Figure.tabPanels{3},'Tag','posInfo');
            if isempty(obj.atlasFile), return; end
            if exist('nexAtlas_recomputePosteriors','file')
                infoLbl.Text = 'Recomputing...'; drawnow;
                subjectDir = fileparts(fileparts(obj.atlasFile));
                nexAtlas_recomputePosteriors(subjectDir);
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
                    [umStr, bridgeStr] = obj.unitMatchStatus_(lbl);
                    D(end+1,:) = {lbl, contrib, n_sess, lu, umStr, bridgeStr}; %#ok<AGROW>
                end
            catch
            end
            tbl.Data = D;
            obj.padTableRows_(tbl);
        end

        % ── Units tab ─────────────────────────────────────────────────────

        function populateUnits(obj)
            pn = obj.Figure.tabPanels{5};
            infoLbl = findobj(pn,'Tag','unitsInfo');
            if isempty(obj.atlasFile) || ~isfile(obj.atlasFile)
                infoLbl.Text = 'No atlas loaded.';
            else
                infoLbl.Text = 'Ready.';
            end
        end

        function runUnitMatch(obj)
            pn = obj.Figure.tabPanels{5};
            infoLbl = findobj(pn,'Tag','unitsInfo');
            if isempty(obj.atlasFile), return; end
            sorterTag = findobj(pn,'Tag','unitsSorterDD').Value;
            if ~exist('nexAtlas_runUnitMatch','file')
                infoLbl.Text = 'nexAtlas_runUnitMatch not found on path.';
                return;
            end
            obj.clearUnitsLog_();
            obj.setUnitsProgress_(0, sprintf('Running UnitMatch (%s)...', sorterTag));
            subjectDir = fileparts(fileparts(obj.atlasFile));
            try
                ok = nexAtlas_runUnitMatch(subjectDir, sorterTag, ...
                    @(frac,label) obj.setUnitsProgress_(frac,label));
                % nexAtlas_runUnitMatch reports its own failures via
                % progressFcn and returns normally (doesn't throw) — ok
                % is the only reliable signal that it actually succeeded.
                % Printing "done" unconditionally here would silently
                % follow a failure message with a false success message.
                if ok
                    obj.setUnitsProgress_(1, sprintf('UnitMatch (%s) done — see Sessions tab for status.', sorterTag));
                end
            catch e
                obj.setUnitsProgress_(0, sprintf('UnitMatch failed: %s', e.message));
            end
            obj.populateSessions('');
        end

        function reconcileCatalog(obj)
            pn = obj.Figure.tabPanels{5};
            infoLbl = findobj(pn,'Tag','unitsInfo');
            if isempty(obj.atlasFile), return; end
            sorterTag = findobj(pn,'Tag','unitsSorterDD').Value;
            if ~exist('nexAtlas_reconcileCatalog','file')
                infoLbl.Text = 'nexAtlas_reconcileCatalog not found on path.';
                return;
            end
            obj.setUnitsProgress_(0, sprintf('Reconciling catalog (%s)...', sorterTag));
            subjectDir = fileparts(fileparts(obj.atlasFile));
            try
                nexAtlas_reconcileCatalog(subjectDir, sorterTag);
                obj.setUnitsProgress_(1, sprintf('Catalog reconciled (%s).', sorterTag));
            catch e
                obj.setUnitsProgress_(0, sprintf('Reconcile failed: %s', e.message));
            end
            obj.populateSessions('');
        end

        % ── Map tab ───────────────────────────────────────────────────────

        function populateMap(obj)
        % Push current subject context into the embedded HTML view. Real
        % unit/edge export isn't wired yet (see ingestLiveData's TODO in
        % index.html) — this proves the MATLAB->HTML Data push path works
        % end to end; the HTML falls back to its own synthetic demo for
        % anything it doesn't recognize.
            if ~isfield(obj.Figure,'mapHTML') || isempty(obj.Figure.mapHTML) || ~isvalid(obj.Figure.mapHTML)
                return;
            end
            obj.Figure.mapHTML.Data = struct('subjectLabel', obj.atlasSubject, 'units', {{}});
        end

        function onMapEvent(obj, ev)
        % Receives events sent from the embedded HTML via
        % htmlComponent.sendEventToMATLAB(...) — e.g. 'unitHover' while
        % scrubbing the 3-D view. Just logged for now; a natural next step
        % is driving e.g. the Reference tab's selection from a click here.
            try
                fprintf('[nexObj_ephysAtlas] map event "%s": %s\n', ...
                    ev.HTMLEventName, jsonencode(ev.HTMLEventData));
            catch
            end
        end

    end

    % ── Private helpers ───────────────────────────────────────────────────────
    methods (Access = private)

        function buildFigure_(obj)
            C = obj.nexon.settings.Colors;
            obj.pal = struct('BG', C.cyberBlack, 'FG', C.cyberGreen, ...
                             'DIM', C.disableGrey, 'ACC', C.cyberGreen, ...
                             'SEP', C.cyberGrey,  'PNL', C.cyberBlack);
            fig = nexFigure_ephysAtlas(obj);
            obj.Figure.fh = fig;
            obj.applyHeadline();
            subj = obj.getSubject_();
            h5   = obj.findAtlasFile_(subj);
            if ~isempty(h5)
                obj.atlasFile    = h5;
                obj.atlasSubject = subj;
                obj.Figure.subjLbl.Text = subj;
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
                case 5,  obj.populateUnits();
                case 6,  obj.populateMap();
            end
        end

        function [umStr, bridgeStr] = unitMatchStatus_(obj, lbl)
        % Compact per-session UnitMatch status across both sorters, for the
        % Sessions tab table: "KS:N RT:N" style counts, and which sorters
        % have been bridged into the catalog (nexAtlas_reconcileCatalog).
            umParts = {}; bridgeParts = {};
            for sorter = ["KS","RT"]
                base = ['/units/sessions/' lbl '/' char(sorter) '/'];
                try
                    gid = h5read(obj.atlasFile, [base 'global_ids']);
                    umParts{end+1} = sprintf('%s:%d', sorter, numel(gid)); %#ok<AGROW>
                catch
                end
                try
                    h5info(obj.atlasFile, [base 'cosine_global_ids']);
                    bridgeParts{end+1} = char(sorter); %#ok<AGROW>
                catch
                end
            end
            if isempty(umParts),     umStr     = '–'; else, umStr     = strjoin(umParts, ' ');     end
            if isempty(bridgeParts), bridgeStr = '–'; else, bridgeStr = strjoin(bridgeParts, ', '); end
        end

        function setUnitsProgress_(obj, frac, label)
        % Resize the hand-built fill panel (uifigure has no native inline
        % progress-bar widget) and update the stage label, then force an
        % immediate repaint. Called both locally (start/end) and as
        % nexAtlas_runUnitMatch's progressFcn callback, so it must be
        % cheap and safe to call from inside that blocking function.
            if ~obj.figAlive_(), return; end
            pn = obj.Figure.tabPanels{5};
            track = findobj(pn,'Tag','unitsProgTrack');
            fill  = findobj(track,'Tag','unitsProgFill');
            infoLbl = findobj(pn,'Tag','unitsInfo');
            frac = max(0, min(1, frac));
            fill.Position(3) = max(0, track.Position(3) * frac);
            infoLbl.Text = label;
            obj.unitsLog_(label);
            drawnow;
        end

        function unitsLog_(obj, msg)
        % Append one line to the Units tab's running transcript — same
        % pattern as iblLog_. Multi-line messages (e.g. the "excluding N
        % session(s): ..." list) get split so each line is its own entry,
        % consistent with how a real console log would wrap it.
            ta = findobj(obj.Figure.tabPanels{5},'Tag','unitsLog');
            if isempty(ta), return; end
            lines = strsplit(char(msg), newline);
            ta.Value = [ta.Value(:)', lines];
        end

        function clearUnitsLog_(obj)
        % Reset the transcript at the start of a fresh run so each run's
        % output starts clean instead of piling up under the last one.
        % uitextarea.Value must be a non-empty cell of char vectors — a
        % truly empty {} is rejected, hence the single blank line.
            ta = findobj(obj.Figure.tabPanels{5},'Tag','unitsLog');
            if isempty(ta), return; end
            ta.Value = {''};
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
            addStyle(tbl, uistyle('BackgroundColor', obj.pal.PNL, 'FontColor', obj.pal.FG));
            try
                [cmap, matched] = nex_axisColorFromRegistry(obj.nexon, 'map', string(regions));
                if ~matched, return; end
                for ri = 1:numel(regions)
                    addStyle(tbl, uistyle('FontColor', cmap(ri,:)), 'row', ri);
                end
            catch
            end
        end

        function padTableRows_(~, tbl)
            ROW_H = 22;  HDR_H = 28;
            nCols = numel(tbl.ColumnName);
            nFit  = floor((tbl.Position(4) - HDR_H) / ROW_H);
            nPad  = max(0, nFit - size(tbl.Data, 1));
            if nPad > 0
                tbl.Data = [tbl.Data; repmat({''}, nPad, nCols)];
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

        function h5 = findAtlasFile_(obj, subj)
            h5 = '';
            if isempty(subj), return; end
            params = obj.nexon.console.BASE.params;
            for base = {params.paths.projDir_cloud, params.paths.projDir_local}
                candidate = fullfile(base{1}, 'Experiments', ...
                    params.extractCfg.experiment, 'Subjects', subj, 'npxls', 'ephys_atlas.h5');
                if isfile(candidate)
                    h5 = candidate;
                    return;
                end
            end
        end

        function subj = getSubject_(obj)
            subj = '';
            ud = obj.nexon.console.BASE.router.UserData;
            for fn = {'subjectDir_cloud', 'subjectDir'}
                if ~isfield(ud, fn{1}), continue; end
                sd = char(ud.(fn{1}));
                if isempty(sd), continue; end
                if sd(end) == filesep, sd = sd(1:end-1); end
                [~, name] = fileparts(sd);
                if ~isempty(name)
                    subj = name;
                    return;
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
