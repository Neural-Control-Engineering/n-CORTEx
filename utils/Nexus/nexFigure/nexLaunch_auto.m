function launched = nexLaunch_auto(nexon, trigger)
% nexLaunch_auto  Fire this machine's configured figures at a pipeline hook.
%
%   launched = nexLaunch_auto(nexon, trigger)
%
% Reads the per-machine auto-launch config (nexLaunch_loadAutoCfg) and, for each
% entry whose .trigger matches `trigger` (or is "*"), launches its {dfID,figType}
% figure via the nexLaunch primitive. This composes Layer 1 into a declarative,
% machine-configurable "scene" fired at the end of a pipeline/routine — drop a
% call at any hook point (nex_panelStartup, stopCapture, ...).
%
%   trigger : the hook tag; entries tagged with it (or "*") fire.
%
% Guards:
%   - skips entries whose dfID is not yet present in the DTS
%   - skips entries whose figType is not a registered figure
%   - session-level dedup: launches each (trigger|dfID|figType) once and reuses
%     it while its figure is alive, so per-trial hooks don't stack duplicates
%
% Returns a string array of "figType <- dfID" for what it launched this call.

    trigger  = string(trigger);
    launched = strings(0,1);

    cfg = nexLaunch_loadAutoCfg();
    if isempty(cfg), return; end

    reg   = nexLaunch_registry();
    store = autoLaunchStore(nexon);      % containers.Map handle — updates in place

    for k = 1:numel(cfg)
        e = cfg(k);
        if ~(e.trigger == "*" || e.trigger == trigger), continue; end
        if ~dfIDPresent(nexon, e.dfID),    continue; end   % source not ready yet
        if ~isfield(reg, char(e.figType)), continue; end   % unknown figure type

        key = char(e.trigger + "|" + e.dfID + "|" + e.figType);
        if isKey(store, key) && figureAlive(store(key))
            continue;                                       % already up — reuse
        end
        try
            obj = nexLaunch(nexon, e.dfID, e.figType);
            store(key) = obj;
            launched(end+1,1) = e.figType + " <- " + e.dfID; %#ok<AGROW>
        catch err
            warning("nexLaunch_auto:entry", "%s/%s: %s", ...
                e.dfID, e.figType, err.message);
        end
    end
end

function tf = dfIDPresent(nexon, dfID)
% Can dtsIO_readDF assemble this dfID from the current DTS? Uses the same shared
% resolver, so the guard never skips a launchable source (nor fires on a missing
% one): disk-backed → HDF5 group present; in-memory → dtsIO_resolveDFID matches.
    tf = false;
    try
        DTS = nexon.console.BASE.DTS;
        if ismember('h5_path', string(DTS.Properties.VariableNames))
            tf = any(string(dtsIO_readDFIDs(DTS)) == string(dfID));   % disk group
        else
            tf = ~isempty(dtsIO_resolveDFID(DTS, dfID));              % in-memory
        end
    catch
    end
end

function store = autoLaunchStore(nexon)
% Per-session dedup store: key -> launched nexObj handle. Lives on the nexon so
% it persists across trigger calls within a session (mirrors the categorical
% cache in nexLaunch_getCategorical).
    if ~isfield(nexon.UserData, 'autoLaunched') || ...
            ~isa(nexon.UserData.autoLaunched, 'containers.Map')
        nexon.UserData.autoLaunched = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    store = nexon.UserData.autoLaunched;
end

function alive = figureAlive(obj)
    alive = false;
    try
        alive = isvalid(obj) && isvalid(obj.Figure.fh);
    catch
    end
end
