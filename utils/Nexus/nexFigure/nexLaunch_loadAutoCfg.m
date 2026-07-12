function cfg = nexLaunch_loadAutoCfg()
% nexLaunch_loadAutoCfg  Load this machine's figure auto-launch config.
%
%   cfg = nexLaunch_loadAutoCfg()
%
% Reads Nexus/Startup/Cache/autoLaunch_<COMPUTERNAME>.json — a JSON array of
%   {"dfID": ..., "figType": ..., "trigger": ...}
% objects. `trigger` names the pipeline hook the entry fires at (e.g.
% "stopCapture", "panelStartup") or "*" for every hook; it may be omitted
% (defaults to "*"). Auto-launch is opt-in per machine: a missing file returns
% an empty struct array (no figures auto-launch).
%
% Returns a struct array with string fields dfID / figType / trigger.

    cfg = struct('dfID', {}, 'figType', {}, 'trigger', {});

    machine = getenv('COMPUTERNAME');   % raw name (hyphens are path-safe); file
                                        % is autoLaunch_<COMPUTERNAME>.json exactly
    p = fullfile(fileparts(which('Nexon')), 'Startup', 'Cache', ...
                 sprintf('autoLaunch_%s.json', machine));
    if ~isfile(p), return; end

    raw = jsondecode(fileread(p));

    % jsondecode yields a struct array when every object shares fields, or a
    % cell array of structs when they differ — normalize both to one shape.
    if iscell(raw), items = raw; else, items = num2cell(raw); end
    for i = 1:numel(items)
        e = items{i};
        if ~isfield(e, 'dfID') || ~isfield(e, 'figType'), continue; end
        c.dfID    = string(e.dfID);
        c.figType = string(e.figType);
        if isfield(e, 'trigger') && ~isempty(e.trigger)
            c.trigger = string(e.trigger);
        else
            c.trigger = "*";
        end
        cfg(end+1) = c; %#ok<AGROW>
    end
end
