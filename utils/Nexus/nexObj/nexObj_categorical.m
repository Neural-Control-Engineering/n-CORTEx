classdef nexObj_categorical < handle
    properties
        classID = "ctg"
        nexon
        Parent
        Partners
        Children=struct();
        dfID_source
        dfID_target
        selectionBus    % categories + items — DTS path (backward compat)
        collector       % View (SRC, VW) + Pointer — RESULTS path
        pMap
        cfg
        DF
        DF_postOp
        STAT
        Figure
    end
    methods

        function nexObj = nexObj_categorical(nexon, Partner, dfID_source, opFcn)
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
            nexObj.DF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, []);
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
            % ── collector — View (SRC, VW) ────────────────────────────────
            % SRC: active data source — "DF" (router), or any RESULTS key
            % VW:  group labels within the active RESULT (empty until reportSTAT)
            nexObj.collector.View    = nexInit_collectorView(nexObj);
            nexObj.collector.Pointer = [];   % populated by applySRC for RESULTS sources
            % ── draw figure ───────────────────────────────────────────────
            nexFigure_categorical(nexObj);
        end

        % ── Source switching ──────────────────────────────────────────────
        function applySRC(nexObj, srcKey)
            % Root entry point for SRC changes.  All panels remain visible
            % (vertically arranged); only the active data path changes.
            srcKey = string(srcKey);
            isResultsSRC = isfield(nexObj.RESULTS, char(srcKey));
            if isResultsSRC
                nexObj.refreshVW(srcKey);
                nexObj.drawFromRESULT(srcKey);
            else
                nexObj.reportStats([]);
            end
        end

        function refreshSRC(nexObj)
            % Update SRC listbox after a new RESULTS entry is added.
            if ~isfield(nexObj.collector, 'View'), return; end
            keys = ["DF"; string(fieldnames(nexObj.RESULTS))];
            bus  = nexObj.collector.View;
            nK   = numel(keys);
            bus.selKeys.SRC    = keys;
            bus.selections.SRC = 1;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC)
                bus.listBoxes.SRC.String = keys;
                bus.listBoxes.SRC.Max    = 1;
                bus.listBoxes.SRC.Value  = 1;
            end
        end

        function refreshVW(nexObj, srcKey)
            % Populate VW listbox from RESULTS.(srcKey) grouping columns.
            if ~isfield(nexObj.RESULTS, char(srcKey)), return; end
            T = nexObj.RESULTS.(char(srcKey));
            DF_STRUCT_FIELDS = ["df","ax","ptr","avgCfg","cov","sem"];
            cols     = string(T.Properties.VariableNames)';
            grpCols  = cols(~ismember(cols, DF_STRUCT_FIELDS));
            if isempty(grpCols)
                vwKeys = "";
            else
                vwKeys = unique(T.(char(grpCols(1))));
            end
            bus = nexObj.collector.View;
            nVW = numel(vwKeys);
            bus.selKeys.VW    = vwKeys;
            bus.selections.VW = 1:nVW;
            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW)
                bus.listBoxes.VW.String = vwKeys;
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = 1:nVW;
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
            C_errorBar = nexObj.nexon.settings.Colors.cyberGreen;
            nexObj.Figure.panel0.graphics.canvas = nexDraw_violin(nexObj.Figure.panel0.tiles.ax, nexObj.STAT, S_categories, C_errorBar);
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
