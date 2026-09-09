classdef nexObj_resultsViewer < handle
% Standalone results viewer — receives R structs from any mdlObj via push()
% and renders performance comparisons in an atlas-style tabbed figure.
%
% Usage:
%   viewer = nexObj_resultsViewer(mdlObj)   % wired to an mdlObj source
%   viewer = nexObj_resultsViewer()         % standalone
%   viewer.push('cv_1', R)                  % add / update a result
%
% The viewer builds its own figure (nexFigure_resultsViewer) at construction.
% It registers itself as mdlObj.Partners.viewer so storeResult() auto-pushes.

    properties
        nexon
        results  = struct()   % results.(id) = R struct
        collector = struct()  % collector.SRC : selected result IDs
        Figure   = struct()   % figure handles + renderFcns
        source               % the mdlObj this viewer is watching (may be [])
    end

    methods
        function obj = nexObj_resultsViewer(source)
            if nargin < 1 || isempty(source)
                obj.nexon  = [];
                obj.source = [];
            else
                obj.nexon  = source.nexon;
                obj.source = source;
                % Register so storeResult auto-pushes
                if ~isstruct(source.Partners), source.Partners = struct(); end
                source.Partners.viewer = obj;
                % Pull any already-stored results
                if isstruct(source.RESULTS)
                    ids = string(fieldnames(source.RESULTS))';
                    for i = 1:numel(ids)
                        obj.results.(ids(i)) = source.RESULTS.(ids(i));
                    end
                end
            end
            obj.collector.SRC     = string.empty;
            obj.collector.srcKeys = string.empty;
            nexFigure_resultsViewer(obj);
        end

        function push(obj, resultID, R)
        % Add or update a result and refresh the SRC listbox.
            obj.results.(resultID) = R;
            % Add to SRC key list if new
            if ~ismember(resultID, obj.collector.srcKeys)
                obj.collector.srcKeys(end+1) = resultID;
                if isfield(obj.Figure, 'srcListBox') && isvalid(obj.Figure.srcListBox)
                    obj.Figure.srcListBox.String = cellstr(obj.collector.srcKeys);
                    obj.Figure.srcListBox.Max    = numel(obj.collector.srcKeys);
                end
            end
        end

        function render(obj)
        % Render the active tab using the currently selected SRC keys.
            if ~isfield(obj.Figure, 'srcListBox') || ~isvalid(obj.Figure.srcListBox)
                return;
            end
            lb      = obj.Figure.srcListBox;
            selIdx  = lb.Value;
            if isempty(obj.collector.srcKeys) || isempty(selIdx)
                return;
            end
            selKeys = obj.collector.srcKeys(selIdx);
            % Dispatch to active tab render closure
            if ~isfield(obj.Figure, 'renderFcns') || ~isstruct(obj.Figure.renderFcns)
                return;
            end
            if ~isfield(obj.Figure.renderFcns, 'active'), return; end
            tab = obj.Figure.renderFcns.active;
            if isfield(obj.Figure.renderFcns, tab)
                obj.Figure.renderFcns.(tab)(selKeys);
            end
        end
    end
end
