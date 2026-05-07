classdef nexObj_categorical < nexObject
    properties
        % classID = "ctg"
        % nexon
        % Parent
        % Partners
        % Children=struct();
        % dfID_source
        % dfID_target
        selectionBus    % categories + items — DTS path (backward compat)
        % collector       % View (SRC, VW) + Pointer — RESULTS path
        % pMap
        % cfg
        % DF
        % DF_postOp        
        % Figure
    end
    methods

        function nexObj = nexObj_categorical(nexon, Partner, dfID_source, opFcn, headline)
            if nargin < 5, headline = []; end
            nexObj = nexObj@nexObject(nexon, [], dfID_source, headline);
            nexObj.classID="ctg";
            nexObj.dfID_source = dfID_source;
            if isempty(Partner)
                nexObj.nexon = nexon;
            else % partner handshake method
                nexObj.Partners.(Partner.classID) = Partner;
                Partner.Partners.(nexObj.classID) = nexObj;
                nexObj.nexon = Partner.nexon;
            end
            % method configuration
            nexObj.cfg.opCfg=[];
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_categorical"));
            % retrieve dataframe
            DF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, []);
            if isempty(DF) || isempty(fieldnames(DF))
                DF = dtsIO_readHDF5(nexObj.nexon, char(nexObj.dfID_source), []);
            end
            nexObj.DF=DF;            
            % compute result
            nexObj.compute();
            % axis control
            nexObj.DF_postOp.ptr = nexInit_axisPointer(nexObj.DF_postOp.df, nexObj.DF_postOp.ax);
            % pooling control
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end
            % upgrade DF (postOp)
            nexObj.DF_postOp = nexObj_DF(nexObj.DF_postOp);
            % ── DTS selection buses (categories + items) ──────────────────
            nexObj.selectionBus.categories = nexSelect_categories(nexObj);
            S = nex_returnSelectionMask(nexObj.selectionBus.categories);
            itemsDict = structfun(@(fieldVal) "", S,"UniformOutput",false);
            nexObj.selectionBus.items = buildSelection(nexObj, itemsDict);
            % selectionBus listener (for DF ax changes)
            nexObj.selectionBus.items.Listeners.ax = addlistener(nexObj.DF_postOp,'ax','PostSet',@(~,~)nexOp_sBus_alignItems2ax(nexObj.selectionBus.items));
            % modify selectionBus hierarchy (arrange selection cascade)
            nexObj.selectionBus.categories.Parent = nexObj.selectionBus.items;
            nexObj.selectionBus.items.Children.sbus = nexObj.selectionBus.categories;
            % ── collector — View (SRC, CLR, CMP, GRP) ────────────────────────
            % categorical omits VW and Pointer — selectionBus.categories/items
            % already serve both roles (group selection + value navigation).
            % CMP / GRP: compareVars / groupVars for reportSTAT, seeded from
            % the active category IDs in the categories bus.
            S_cat   = nex_returnSelectionMask(nexObj.selectionBus.categories);
            catIDs  = string(struct2cell(S_cat))';
            catIDs  = strrep(catIDs(~strcmp(catIDs,"None")), "--", "_");
            viewDict.SRC = "DTS";
            viewDict.CLR = "";
            viewDict.CMP = catIDs;
            viewDict.GRP = catIDs;
            nexObj.collector.View = buildSelection(nexObj, viewDict);
            % ── draw figure ───────────────────────────────────────────────
            nexFigure_categorical(nexObj);
        end

        % ── Source switching ──────────────────────────────────────────────
        function applySRC(nexObj, srcKey)
            % Root entry point for SRC changes.
            % 1. updateSentinel — rebuilds DF_postOp sentinel for the new SRC
            %    (DTS: pool from raw DF; RESULTS: forge DF_postOp.ax from ax_ columns).
            %    PostSet on DF_postOp.ax fires automatically → nexOp_sBus_alignItems2ax.
            % 2. restoreItems — re-enumerates all category slots via enumerateItemsFor,
            %    which dispatches to DTS registry or RESULTS table based on current SRC.
            % 3. Draw.
            srcKey = string(srcKey);
            nexObj.updateSentinel();
            nexObj.restoreItems();
            if isfield(nexObj.RESULTS, char(srcKey))
                nexObj.drawFromRESULT(srcKey);
            else
                % nexObj.reportStats([]);
            end
        end

        function refreshSRC(nexObj)
            % Update SRC listbox after a new RESULTS entry is added.
            if ~isfield(nexObj.collector, 'View'), return; end
            keys = ["DTS"; string(fieldnames(nexObj.RESULTS))];
            bus  = nexObj.collector.View;
            bus.selKeys.SRC    = keys;
            bus.selections.SRC = 1;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC)
                bus.listBoxes.SRC.String = keys;
                bus.listBoxes.SRC.Max    = 1;
                bus.listBoxes.SRC.Value  = 1;
            end
        end

        function srcKey = getCurrentSRC(nexObj)
            % Return the currently selected SRC key as a string.
            if ~isfield(nexObj.collector, 'View'), srcKey = "DTS"; return; end
            bus  = nexObj.collector.View;
            keys = bus.selKeys.SRC;
            idx  = bus.selections.SRC;
            if isempty(idx) || idx < 1 || idx > numel(keys)
                srcKey = "DTS";
            else
                srcKey = string(keys(idx));
            end
        end

        function items = enumerateItemsFor(nexObj, category)
            % SRC-aware item enumeration for the items bus (Node 1 replacement).
            % DTS path  → nexOp_enumerateCategory (DF_postOp.ax then DTS registry).
            % RESULTS path → unique values from the matching RESULTS table column.
            %   Category names use "ax--fieldname" convention; RESULTS columns use
            %   "ax_fieldname" — strrep maps between them.
            srcKey = nexObj.getCurrentSRC();
            if strcmp(srcKey, "DTS") || ~isfield(nexObj.RESULTS, char(srcKey))
                items = nexOp_enumerateCategory(nexObj, category);
            else
                T   = nexObj.RESULTS.(char(srcKey));
                col = char(strrep(string(category), "--", "_"));
                if ismember(col, T.Properties.VariableNames)
                    raw = T.(col);
                    if iscell(raw), raw = string(raw); end
                    items = unique(string(raw), "stable");
                else
                    items = "";
                end
            end
        end

        function updateSentinel(nexObj)
            % Forge DF_postOp.ax to match the active SRC (Node 2 replacement).
            % DTS path    — rebuild DF_postOp normally via updateScope (pools raw DF).
            %               PostSet on DF_postOp.ax fires → nexOp_sBus_alignItems2ax.
            % RESULTS path — extract ax_* columns from RESULTS table, build ax struct
            %               from unique values, and assign to DF_postOp.ax directly.
            %               PostSet on DF_postOp.ax fires → nexOp_sBus_alignItems2ax.
            srcKey = nexObj.getCurrentSRC();
            if strcmp(srcKey, "DTS") || ~isfield(nexObj.RESULTS, char(srcKey))
                nexObj.updateScope();
            else
                T    = nexObj.RESULTS.(char(srcKey));
                cols = string(T.Properties.VariableNames)';
                axCols = cols(startsWith(cols, "ax_"));
                newAx = struct();
                for i = 1:numel(axCols)
                    field = char(extractAfter(axCols(i), "ax_"));
                    raw   = T.(char(axCols(i)));
                    if iscell(raw), raw = [raw{:}]; end
                    newAx.(field) = unique(raw, "stable");
                end
                nexObj.DF_postOp.ax = newAx;
            end
        end

        function restoreItems(nexObj)
            % Re-enumerate every category slot in the items bus from the current SRC.
            % Calls sBus.updateScope per key — which dispatches to enumerateItemsFor —
            % so DTS and RESULTS paths are handled automatically by the current SRC.
            S    = nex_returnSelectionMask(nexObj.selectionBus.categories);
            sBus = nexObj.selectionBus.items;
            keys = fieldnames(S);
            for i = 1:numel(keys)
                sBus.updateScope(keys{i}, S.(keys{i}));
            end
        end

        function drawFromRESULT(nexObj, srcKey)
            % Visualize RESULTS.(srcKey) filtered by VW selection.
            % Placeholder — full implementation follows reportSTAT.
            if ~isfield(nexObj.RESULTS, char(srcKey)), return; end
            if isfield(nexObj.Figure.panel0, 'graphics')
                nexDraw_clearViolin(nexObj);
            end
            % TODO: dispatch to draw function based on result shape
        end

        % ── DTS path (existing) ───────────────────────────────────────────
        function reportStats(nexObj, idxSel)
            S_categories = nex_returnSelectionMask(nexObj.selectionBus.categories);
            S_items = nex_returnSelectionMask(nexObj.selectionBus.items);
            nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_categories, S_items, idxSel);
            try
                nexObj.STAT.df = cell2mat(nexObj.STAT.df);
            catch e
                disp(getReport(e));
            end
            try
                nexObj.drawCanvas();
            catch e
                disp(getReport(e));
            end
        end

        function drawCanvas(nexObj)
            if isfield(nexObj.Figure.panel0,"graphics")
                nexDraw_clearViolin(nexObj);
            end
            S_categories = nex_returnSelectionMask(nexObj.selectionBus.categories);
            S_items = nex_returnSelectionMask(nexObj.selectionBus.items);
            C_errorBar = nexObj.nexon.settings.Colors.cyberGreen;
            % nexObj.Figure.panel0.graphics.canvas = nexDraw_violin(nexObj.Figure.panel0.tiles.ax, nexObj.STAT, S_categories, C_errorBar);
            srcKey = nexObj.getCurrentSRC();
            switch srcKey
                case 'DTS'
                    STAT=nexObj.STAT;
                otherwise
                    S_sel = outerjoinStructs(S_categories, S_items);
                    S_sel = rmfield(S_sel,"None");
                    STAT=nexObj.RESULTS.(srcKey);
                    % filter using selection
                    STAT = nexOp_filterSTAT(STAT, S_sel);
            end
            nexObj.Figure.panel0.graphics.canvas = nexDraw_violin(nexObj.Figure.panel0.tiles.ax, STAT, S_categories, C_errorBar);
        end

        function visualize(nexObj)
            nexObj.cfg.visCfg.fcn(nexObj, nexObj.cfg.visCfg.entryParams);
        end

        function compute(nexObj)
            try
                nexObj.DF_postOp = nexObj.cfg.compCfg.fcn(DF, compArgs);
            catch e
                disp(getReport(e));
                nexObj.DF_postOp = nexObj.DF;
            end
            operate(nexObj);
        end

        function operate(nexObj)
            try
                nexObj.DF_postOp = nexObj.cfg.opCfg.fcn(nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end
        end

        function setAxisPointer(nexObj, src, event, axSel)
            axVal = src.Value;
            nexObj.DF = nex_setAxisPointer(nexObj.DF,axSel, axVal);
            nexObj.updateScope();
        end

        function updateScope(nexObj)
            ptr = nexObj.DF_postOp.ptr;
            pm  = nexObj.pMap;
            DF_pooled = nexOp_poolAxes(pm, nexObj.DF, ptr);
            nexObj.DF_postOp.df = DF_pooled.df;
            nexObj.DF_postOp.ax = DF_pooled.ax;
        end

        function reportSTAT(nexObj, fcn, compareVars, groupVars, resID, dfID, nBins)
            % 1. Run base reportSTAT — calls nexOp_reportSTAT and stores the
            %    initial comparison result in RESULTS.(resID), then refreshSRC.
            if nargin < 6
                reportSTAT@nexObject(nexObj, fcn, compareVars, groupVars, resID);
            else
                reportSTAT@nexObject(nexObj, fcn, compareVars, groupVars, resID, dfID, nBins);
            end
            % 2. Expand every row of RESULTS.(resID) along all DF axes.
            %    For each row: build a DF struct, construct SS_ax covering all
            %    ax fields at all values (full breakout), call nexStat_breakoutDF,
            %    then replicate the row's grouping columns across the expanded rows.
            T          = nexObj.RESULTS.(resID);
            STRUCT_COLS = ["df","ax","ptr"];
            rows        = cell(height(T), 1);
            for i = 1:height(T)
                % Unpack — table cells may wrap the values one level deep
                df_i  = T.df(i);  if iscell(df_i),  df_i  = df_i{1};  end
                ax_i  = T.ax(i);  if iscell(ax_i),  ax_i  = ax_i{1};  end
                ptr_i = T.ptr(i); if iscell(ptr_i), ptr_i = ptr_i{1}; end
                DF.df  = df_i;
                DF.ax  = ax_i;
                DF.ptr = ptr_i;
                % SS_ax: all ax fields, all values → complete axis breakout.
                % nexStat_breakoutDF expects fieldnames of the form "ax_<field>"
                % (matches sprintf("ax_%s", axID) convention in nexStat_breakoutDF).
                SS_ax    = struct();
                axFields = string(fieldnames(DF.ax))';
                for fi = 1:numel(axFields)
                    SS_ax.(sprintf("ax_%s", axFields(fi))) = DF.ax.(char(axFields(fi)));
                end
                dfSet = nexStat_breakoutDF(DF, SS_ax);
                % Replicate grouping columns (non-structural) across expanded rows
                grpCols = string(T.Properties.VariableNames);
                grpCols = grpCols(~ismember(grpCols, STRUCT_COLS));
                if ~isempty(grpCols)
                    dfSet = [dfSet, repmat(T(i, cellstr(grpCols)), height(dfSet), 1)];
                end
                rows{i} = dfSet;
            end
            nexObj.RESULTS.(resID) = cat(1, rows{:});
            nexObj.refreshSRC();
        end

        function [X, Y, Z, L] = binSTAT(nexObj)
            STAT = nexObj.STAT;
            S_categories = nex_returnSelectionMask(nexObj.selectionBus.categories);
            categories = cellfun(@(f) S_categories.(f), fieldnames(S_categories));
            categories = strrep(categories(~strcmp(categories,"None")),"--","_")';
            [X, xTicks, xLabels] = nexStat_binSTAT(STAT, categories);
            xLabels = xLabels{1}; xTicks = xTicks{1};
            L = arrayfun(@(x) xLabels(x==xTicks), X, "UniformOutput",true);
            switch class(STAT.df)
                case 'cell'
                    Y = cell2mat(STAT.df);
                otherwise
                    Y = STAT.df;
            end
            [Z, L] = nexOp_accumCols(X, Y, L);
        end

    end
end
