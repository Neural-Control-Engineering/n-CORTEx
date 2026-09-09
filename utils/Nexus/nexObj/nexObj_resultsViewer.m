classdef nexObj_resultsViewer < nexObject
% Results viewer — nexObject subclass that receives R structs via push() and
% renders performance metrics in an atlas-style tabbed figure.
%
% Provisional implementation: SRC / VW (fold filter) / Pointer (time window)
% buses are wired; Domain bus and full DF-structured rendering are deferred.
%
% Usage:
%   viewer = nexObj_resultsViewer(mdlObj)   % wired to an mdlObj source
%   viewer = nexObj_resultsViewer(nexon)    % standalone with nexon for colours
%   viewer = nexObj_resultsViewer()         % fully standalone (no colour registry)
%   viewer.push('cv_1', R)                  % add / update a result

    properties
        source   % mdlObj this viewer watches; may be empty
    end

    methods
        function obj = nexObj_resultsViewer(source, headline)
            if nargin < 1 || isempty(source), source = []; end
            if nargin < 2 || isempty(headline), headline = 'Results Viewer'; end

            % Resolve nexon from source
            if isempty(source)
                nexon_ = [];
            elseif isprop(source, 'nexon') || isfield(source, 'nexon')
                nexon_ = source.nexon;
            elseif isa(source, 'Nexon')
                nexon_ = source; source = [];
            else
                nexon_ = [];
            end

            obj = obj@nexObject(nexon_, [], "", headline);
            obj.classID = "rv";

            % No DTS pull — seed empty DF_postOp
            obj.DF_postOp = struct('df', [], 'ax', struct(), 'ptr', struct());
            obj.domain    = struct('D1', string.empty, 'D2', string.empty, ...
                                   'axes', string.empty, 'F', "", 'animate', "");

            % View bus: SRC = result IDs, VW = fold filter, CLR = empty
            viewDict.SRC = "";
            viewDict.VW  = "";
            viewDict.CLR = "";
            obj.collector.View = nexInit_collectorView(obj, viewDict);

            % Wire to source and pull existing results
            if ~isempty(source) && ~isa(source, 'Nexon')
                obj.source = source;
                if ~isstruct(source.Partners), source.Partners = struct(); end
                source.Partners.viewer = obj;
                if isstruct(source.RESULTS) && ~isempty(fieldnames(source.RESULTS))
                    ids = string(fieldnames(source.RESULTS))';
                    for i = 1:numel(ids)
                        obj.RESULTS.(ids(i)) = source.RESULTS.(ids(i));
                    end
                end
            end

            isHeadless = ~isempty(nexon_) && isfield(nexon_, 'settings') && ...
                         isfield(nexon_.settings, 'headless') && nexon_.settings.headless;
            if ~isHeadless
                nexFigure_resultsViewer(obj);
                if isstruct(obj.RESULTS) && ~isempty(fieldnames(obj.RESULTS))
                    obj.refreshSRC();
                end
            end
        end

        function push(obj, resultID, R)
        % Add / update a result and refresh the SRC panel.
            obj.RESULTS.(resultID) = R;
            obj.refreshSRC();
        end

        function refreshSRC(obj)
        % Override: list only RESULTS keys — no "DF" / "DTS" base entry.
            if ~isfield(obj.collector, 'View'), return; end
            bus  = obj.collector.View;
            keys = string(fieldnames(obj.RESULTS))';
            nK   = numel(keys);
            bus.selKeys.SRC    = keys;
            bus.selections.SRC = nK;
            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                bus.listBoxes.SRC.String = cellstr(keys);
                bus.listBoxes.SRC.Max    = 1;
                bus.listBoxes.SRC.Value  = max(1, nK);
            end
            if nK > 0
                obj.applySRC(char(keys(end)));
            end
        end

        function applySRC(obj, srcKey)
        % Update SRC selection, forge DF_postOp from R.ax, rebuild Pointer, visualize.
            if ~isfield(obj.RESULTS, srcKey), return; end
            bus = obj.collector.View;
            idx = find(string(bus.selKeys.SRC) == string(srcKey), 1);
            if ~isempty(idx)
                bus.selections.SRC = idx;
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                        && isvalid(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.Value = idx;
                end
            end

            % Forge DF_postOp.ax from result axes for Pointer / domain inference
            R = obj.RESULTS.(srcKey);
            if isstruct(R) && isfield(R, 'ax')
                obj.DF_postOp = struct('df', [], 'ax', R.ax, 'ptr', struct());
                try
                    obj.DF_postOp = nex_initAxisPointer_v2(obj.DF_postOp);
                catch
                end
                obj.domain = obj.inferDomain();
                obj.initPointerBus();
                obj.rebuildPointerPanel();
                obj.refreshVW_rv(R);
            end
            obj.visualize();
        end

        function refreshVW_rv(obj, R)
        % Populate VW with fold indices from R.ax.fold.
            if ~isfield(obj.collector, 'View'), return; end
            bus = obj.collector.View;
            if isstruct(R) && isfield(R, 'ax') && isfield(R.ax, 'fold')
                foldVals = string(num2cell(R.ax.fold(:)))';
                nF       = numel(foldVals);
            else
                foldVals = string.empty;
                nF       = 0;
            end
            bus.selKeys.VW    = foldVals;
            bus.selections.VW = 1:nF;
            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                    && isvalid(bus.listBoxes.VW)
                bus.listBoxes.VW.String = cellstr(foldVals);
                bus.listBoxes.VW.Max    = max(1, nF);
                bus.listBoxes.VW.Value  = 1:nF;
            end
        end

        function rebuildPointerPanel(obj)
        % Delete and rebuild pointer controls inside the stored container panel.
            if ~isfield(obj.Figure, 'ptrContainer'), return; end
            ph = obj.Figure.ptrContainer;
            if isempty(ph) || ~isvalid(ph), return; end
            delete(ph.Children);
            if isempty(obj.collector.Pointer) || isempty(obj.nexon), return; end
            try
                nexObj_listCfgPanel(obj.nexon, struct('ph', ph), ...
                    obj.collector.Pointer, []);
            catch
            end
        end

        function visualize(obj)
        % Dispatch to the active tab renderer (zero-arg closure reading from obj).
            if ~isfield(obj.Figure, 'renderFcns'), return; end
            tab = char(obj.Figure.renderFcns.active);
            if isfield(obj.Figure.renderFcns, tab)
                try
                    obj.Figure.renderFcns.(tab)();
                catch ME
                    fprintf('[nexObj_resultsViewer.visualize] %s\n', ME.message);
                end
            end
        end
    end
end
