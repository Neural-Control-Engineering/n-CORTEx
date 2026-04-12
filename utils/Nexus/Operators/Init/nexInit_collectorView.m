function bus = nexInit_collectorView(nexObj, viewDict)
% Build collector.View selectionBus with guaranteed SRC, VW, CLR keys.
%
% Every nexObject View bus includes these three standard keys:
%   SRC — active data source ("DF" by default, or any RESULTS key)
%   VW  — group labels within the active RESULT (empty until reportSTAT)
%   CLR — column used for per-point colorization (empty by default)
%
% Additional subclass-specific keys (e.g. AVG for nexObj_stateSpace) are
% passed in via viewDict and merged in before the standard keys are appended,
% so they appear first in the bus ordering.
%
% Usage
%   nexObj.collector.View = nexInit_collectorView(nexObj);
%   nexObj.collector.View = nexInit_collectorView(nexObj, viewDict);

    if nargin < 2 || isempty(viewDict)
        viewDict = struct();
    end
    % Append standard keys as defaults (do not overwrite caller-supplied values)
    if ~isfield(viewDict, 'SRC'), viewDict.SRC = "DF"; end
    if ~isfield(viewDict, 'VW'),  viewDict.VW  = "";   end
    if ~isfield(viewDict, 'CLR'), viewDict.CLR = "";   end

    bus = buildSelection(nexObj, viewDict);
end
