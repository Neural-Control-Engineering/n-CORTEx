classdef nexObj_polyGraph < nexObject

    properties        
    end

    methods

        function nexObj = nexObj_polyGraph(nexon, Parent, Origin, dfID_source, opCfgFcn, headline)
            if nargin < 5, opCfgFcn = []; end
            if nargin < 6, headline  = []; end

            nexObj = nexObj@nexObject(nexon, Parent, dfID_source, headline);
            nexObj.classID = "pgph";
            %% DF source
            if ~isempty(Parent)
                nexObj.DF = Parent.DF_postOp;
                nexObj.Parent.Children.(nexObj.classID) = nexObj;
            else
                nexObj.DF = dtsIO_readDF(nexon, dfID_source, []);
            end

            %% Origin — explicit > Parent > self
            if ~isempty(Origin)
                nexObj.Origin = Origin;
            elseif ~isempty(Parent)
                nexObj.Origin = Parent;
            else
                nexObj.Origin = nexObj;
            end

            %% Config
            if ~isempty(opCfgFcn)
                nexObj.cfg.opCfg = nex_generateCfgObj(opCfgFcn);
            else
                nexObj.cfg.opCfg = [];
            end
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_polyGraph"));
            nexObj.cfg.aniCfg = nex_generateCfgObj(str2func("nexObject.stepAnimate"));

            %% DF_postOp — apply operation, init ptr
            nexObj.operate();

            %% Pool map
            try
                nexObj.pMap = nexInit_pMap(nexObj, nexObj.DF_postOp);
            catch e
                disp(getReport(e));
            end

            %% Domain
            nexObj.domain = nexObj.inferDomain();

            %% Collector — View (SRC / CTG / VW / CLR)
            nexObj.initCollectorView();

            %% Collector — Domain (D1 = x-axis, D2 = stacking axis, ANI single)
            axisKeys = string(fieldnames(nexObj.DF_postOp.ax))';
            if isempty(axisKeys), axisKeys = ""; end
            domainDict.D1  = axisKeys;
            domainDict.D2  = axisKeys;
            domainDict.ANI = axisKeys;
            nexObj.collector.Domain = buildSelection(nexObj, domainDict);

            % Seed defaults: D1 = sweep axis (e.g. t), D2 = first complement (e.g. chans)
            if ~isequal(axisKeys, "")
                sweepAx = nexObj.domain.D2(1);
                d1Idx = find(ismember(axisKeys, sweepAx), 1);
                if ~isempty(d1Idx)
                    nexObj.collector.Domain.selections.D1 = d1Idx;
                end
                if ~isempty(nexObj.domain.D1) && ~isequal(nexObj.domain.D1, "")
                    d2Idx = find(ismember(axisKeys, nexObj.domain.D1(1)), 1);
                    if ~isempty(d2Idx)
                        nexObj.collector.Domain.selections.D2 = d2Idx;
                    end
                end
                aniIdx = find(ismember(axisKeys, nexObj.domain.animate), 1);
                if ~isempty(aniIdx)
                    nexObj.collector.Domain.selections.ANI = aniIdx;
                end
            end

            %% Collector — Pointer (one key per DF.ax field, full multi-select)
            nexObj.initPointerBus();

            %% Figure
            nexFigure_polyGraph(nexObj);

            %% Player
            nexObj.player = timer( ...
                'Period',        0.1, ...
                'BusyMode',      'drop', ...
                'TimerFcn',      @(~,~) nexObj.stepAnimate(nexObj.cfg.aniCfg.entryParams), ...
                'ExecutionMode', 'fixedRate');
        end

        % ── Core methods ──────────────────────────────────────────────────

        function operate(nexObj)
            % Save ptr handle before any DF_postOp replacement
            if ~isempty(nexObj.DF_postOp) && isstruct(nexObj.DF_postOp) ...
                    && isfield(nexObj.DF_postOp, 'ptr') ...
                    && isa(nexObj.DF_postOp.ptr, 'nexObj_ptr')
                savedPtr = nexObj.DF_postOp.ptr;
            else
                savedPtr = [];
            end

            if ~isempty(nexObj.cfg.opCfg)
                opArgs           = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.opFcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end

            % Restore or initialise ptr — never create a new handle after construction
            if ~isempty(savedPtr)
                nex_updateAxisPointer(savedPtr, nexObj.DF_postOp);
                nexObj.DF_postOp.ptr = savedPtr;
            else
                nexObj.DF_postOp.ptr = nexInit_axisPointer( ...
                    nexObj.DF_postOp.df, nexObj.DF_postOp.ax);
            end
        end

        function buildFigure(nexObj)
            nexFigure_polyGraph(nexObj);
        end

        function visualize(nexObj)
            visArgs = nexObj.cfg.visCfg.entryParams;
            nexVisualization_polyGraph(nexObj, visArgs);
        end

        function updateScope(nexObj)
            if ~isempty(nexObj.Parent)
                nexObj.DF = nexObj.Parent.DF_postOp;
            end
            nexObj.operate();
            nexObj.visualize();
        end


    end
end
