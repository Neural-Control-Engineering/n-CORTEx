classdef nexObj_categorical < handle
    properties
        classID = "ctg"
        nexon
        Parent
        Partners
        Children=struct();
        dfID_source
        dfID_target
        selectionBus
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
            % nexObj.DF_postOp =  nex_initAxisPointer_v2(nexObj.DF_postOp);       
            nexObj.DF_postOp.ptr = nexInit_axisPointer(nexObj.DF_postOp.df, nexObj.DF_postOp.ax);
            % pooling control
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end
            % upgrade DF (postOp)
            nexObj.DF_postOp = nexObj_DF(nexObj.DF_postOp);
            % selection Busses
            nexObj.selectionBus.categories = nexSelect_categories(nexObj);
            S = nex_returnSelectionMask(nexObj.selectionBus.categories);
            % itemsDict = structfun(@(fieldVal) nexOp_enumerateCategory(nexObj, fieldVal), S,"UniformOutput",false);
            itemsDict = structfun(@(fieldVal) "", S,"UniformOutput",false);
            % itemsDict = nexOp_itemize()
            nexObj.selectionBus.items = buildSelection(nexObj, itemsDict);
            % selectionBus listener (for DF ax changes)
            nexObj.selectionBus.items.Listeners.ax = addlistener(nexObj.DF_postOp,'ax','PostSet',@(~,~)nexOp_sBus_alignItems2ax(nexObj.selectionBus.items));
            % modify selectionBus heirarchy (arrange selection cascade)
            nexObj.selectionBus.categories.Parent = nexObj.selectionBus.items;
            nexObj.selectionBus.items.Children.sbus = nexObj.selectionBus.categories;
            % draw figure
            nexFigure_categorical(nexObj);
        end

        function reportStats(nexObj, idxSel)            
            % use category selection to group pre-selected DFs into stat metrics
            % leverage comp and opFcns if desired (to get final categories X1, X2,
            % X.., XN)            
            % if isempty(idx_sel)
            %         S = nex_returnSelectionMask(nexObj.nexon.console.BASE.controlPanel.averagingSelection);
            %         idxSel = nex_applySelectionMask(nexObj.nexon.console.BASE.DTS,S);
            %         TF = dtsIO_readTF(nexObj.nexon, nexObj.dfID_source, idxSel);
            % else
            %         TF = dtsIO_readTF(nexObj.nexon, nexObj.dfID_source, idx_sel);
            % end
            % group selections
            % nexObj.STAT = 
            S_categories = nex_returnSelectionMask(nexObj.selectionBus.categories);
            S_items = nex_returnSelectionMask(nexObj.selectionBus.items);
            nexObj.STAT = nexOp_compileSTAT(nexObj, nexObj.dfID_source, S_categories, S_items, idxSel);
            try
                nexObj.STAT.df = cell2mat(nexObj.STAT.df);
            catch e
                disp(getReport(e));
            end
            % visualize result
            % nexObj.visualize();
            try
                nexObj.drawCanvas();
            catch e
                disp(getReport(e));
            end
        end

        function drawCanvas(nexObj)
            % nexObj.Figure.panel0.graphics. nexDraw_violin();
            % categories = nexOp_listCategories(nexObj.nexon)';
            % categories = nexObj.selectionBus.categories.selKeys.C1';
            % clear canvas
            if isfield(nexObj.Figure.panel0,"graphics")
                nexDraw_clearViolin(nexObj);
            end
            % draw new canvas
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
            %% apply pooling
            ptr = nexObj.DF_postOp.ptr; % use initialized pointer from current DF_postOp
            pm = nexObj.pMap;
            DF_pooled = nexOp_poolAxes(pm, nexObj.DF, ptr);
            % update fields (without losing ptr)
            nexObj.DF_postOp.df = DF_pooled.df; nexObj.DF_postOp.ax = DF_pooled.ax;
        end

        function [X, Y, Z, L] = binSTAT(nexObj)
            STAT = nexObj.STAT;
            S_categories = nex_returnSelectionMask(nexObj.selectionBus.categories);
            categories = cellfun(@(f) S_categories.(f), fieldnames(S_categories));
            categories = strrep(categories(~strcmp(categories,"None")),"--","_")';
            [X, xTicks, xLabels] = nexStat_binSTAT(STAT, categories);
            % label bookkeeping
            xLabels = xLabels{1}; xTicks = xTicks{1};
            L = arrayfun(@(x) xLabels(x==xTicks), X, "UniformOutput",true);
            % DRAWING    
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