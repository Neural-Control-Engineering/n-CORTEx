classdef nexObj_monoGraph < nexObject
    properties
        polyGraph
    end

    methods
        function nexObj = nexObj_monoGraph(Parent, Origin, nexon, dfID_source, opCfgFcn, DF, headline)
            if nargin < 7, headline = []; end
            nexObj = nexObj@nexObject(nexon, Parent, dfID_source, headline);
            nexObj.classID = "mgph";

            if nargin >= 6 && ~isempty(DF)
                nexObj.DF = DF;
            end

            if isempty(Parent)
                nexObj.nexon       = nexon;
                nexObj.dfID_source = dfID_source;
                if ~isempty(dfID_source)
                    nexObj.DF = dtsIO_readDF(nexon, dfID_source, []);
                end
                nexObj.Origin = nexObj;
            else
                nexObj.Parent      = Parent;
                nexObj.dfID_source = dfID_source;
                if isempty(Origin)
                    if isa(Parent,"Nexon")
                        nexObj.Origin=Parent;
                    else
                        nexObj.Origin = Parent.Origin;
                    end
                else
                    nexObj.Origin = Origin;
                end
                if isa(Parent,"Nexon")
                    nexObj.nexon=Parent;
                else
                    nexObj.nexon = Parent.nexon;
                end
                nexObj.Parent.Children.(nexObj.classID) = nexObj;
                % Categorical parent: load own DF — parent's DF_postOp is unrelated data.
                % Non-categorical parent: inherit parent's post-op DF as scope.
                if strcmp(Parent.classID, 'ctg') && ~isempty(dfID_source)
                    nexObj.DF = dtsIO_readDF(nexObj.nexon, dfID_source, []);
                elseif isa(Parent,"Nexon")
                    nexObj.DF = dtsIO_readDF(nexObj.nexon, dfID_source, []);
                else
                    nexObj.DF = Parent.DF_postOp;
                end
            end

            % Config / op
            if ~isempty(opCfgFcn)
                nexObj.cfg.opCfg = nex_generateCfgObj(opCfgFcn);
                nexObj.operate();
            else
                nexObj.cfg.opCfg = [];
                nexObj.DF_postOp = nexObj.DF;
            end
            nexObj.DF_postOp  = nex_initAxisPointer_v2(nexObj.DF_postOp);
            nexObj.pMap       = nexInit_pMap(nexObj, nexObj.DF_postOp);
            nexObj.cfg.visCfg = nex_generateCfgObj(str2func("nexVisualization_monoGraph"));

            % STAT + collector.View (base methods)
            nexObj.compileSTAT();
            nexObj.initCollectorView();

            nexObj.buildFigure();
        end

        % ── Core ──────────────────────────────────────────────────────────

        function visualize(nexObj)
            nexVisualization_monoGraph(nexObj, nexObj.cfg.visCfg.entryParams);
        end

        function buildFigure(nexObj)
            nexFigure_monoGraph(nexObj);
        end

        function updateScope(nexObj)
            if ~isempty(nexObj.Parent) && ~strcmp(nexObj.Parent.classID, 'ctg')
                nexObj.DF = nexObj.Parent.DF_postOp;
            end
            nexObj.operate();
            nexObj.visualize();
        end

        % ── Overrides: call base then visualize immediately ────────────────

        function reportAverage(nexObj, resultID, nBins, STAT)
            nexObj.compileSTAT;
            if nargin < 2, resultID = []; end
            if nargin < 3, nBins = 4; end
            if nargin < 4 
                reportAverage@nexObject(nexObj, resultID, nBins); 
            else
                reportAverage@nexObject(nexObj, resultID, nBins, STAT); 
            end
            % reportAverage@nexObject(nexObj, resultID, nBins);
            nexObj.visualize();
        end

        function reportSTAT(nexObj, fcn, compareVars, groupVars, resID, dfID, nBins)
            if nargin < 6
                reportSTAT@nexObject(nexObj, fcn, compareVars, groupVars, resID);
            else
                reportSTAT@nexObject(nexObj, fcn, compareVars, groupVars, resID, dfID, nBins);
            end
            % AVERAGE BY COMPAREVARS
            STAT=nexObj.RESULTS.(resID);
            nexObj.reportAverage(resID, nBins, STAT);
            if ismethod(nexObj,"refreshSRC")
                nexObj.refreshSRC();
            end
        end

        function applySRC(nexObj, srcKey)
            applySRC@nexObject(nexObj, srcKey);
            nexObj.visualize();
        end

        % ── operate (preserved) ───────────────────────────────────────────

        function operate(nexObj)
            if isfield(nexObj.DF_postOp, 'ptr')
                oldPtr = nexObj.DF_postOp.ptr;
            else
                oldPtr = [];
            end
            if ~isempty(nexObj.cfg.opCfg)
                opArgs = nexObj.cfg.opCfg.entryParams;
                nexObj.DF_postOp = nexObj.cfg.opCfg.opFcn(nexObj.DF, opArgs);
            else
                nexObj.DF_postOp = nexObj.DF;
            end
            if ~isempty(oldPtr)
                nexObj.DF_postOp = nex_initAxisPointer_v2(nexObj.DF_postOp);
                newPtr = nexObj_ptr(nexObj.DF_postOp.ptr);
                f = fieldnames(newPtr);
                for i = 1:numel(f)
                    oldPtr.(f{i}) = newPtr.(f{i});
                end
                nexObj.DF_postOp.ptr = oldPtr;
            end
        end
    end
end
