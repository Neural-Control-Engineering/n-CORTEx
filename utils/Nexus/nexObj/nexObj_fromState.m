function nexObj = nexObj_fromState(state, nexon, Partner)
% Reconstruct a headless nexObject subclass from a saved state struct.
%
%   nexObj = nexObj_fromState(state, nexon)
%   nexObj = nexObj_fromState(state, nexon, Partner)
%
%   state   : struct produced by nexObj.saveState()
%   nexon   : manifest nexon (from nexon_fromManifest)
%   Partner : optional partner nexObject (pass [] if none)
%
% After construction the object reads data from the manifest nexon's HDF5.
% Saved selection and cfg state is restored so the object behaves exactly
% as it did in the original session.

    if nargin < 3, Partner = []; end

    % ── Construct the subclass (headless nexon has settings.headless = true)
    initFcn = str2func(state.className);

    % Most nexObject subclasses follow (nexon, Partner, dfID_source, opFcn, headline).
    % opFcn is typically empty at construction — restored via nex_restoreCfg.
    nexObj = initFcn(nexon, Partner, state.dfID_source, [], state.headline);

    % ── Restore domain ───────────────────────────────────────────────────────
    if isfield(state, 'domain') && ~isempty(state.domain)
        fields = fieldnames(state.domain);
        for i = 1:numel(fields)
            nexObj.domain.(fields{i}) = state.domain.(fields{i});
        end
    end

    % ── Restore cfg (generic — handles visCfg, opCfg, etc.) ─────────────────
    if isfield(state, 'cfg') && ~isempty(state.cfg)
        nex_restoreCfg(nexObj.cfg, state.cfg);
    end

    % ── Restore collector selection values ───────────────────────────────────
    if isfield(state, 'collector') && ~isempty(state.collector)
        restoreCollector(nexObj, state.collector);
    end

    % ── Restore selectionBus (nexObj_categorical and similar) ────────────────
    if isfield(state, 'selectionBus') && ~isempty(state.selectionBus) ...
            && isprop(nexObj, 'selectionBus')
        restoreSelectionBus(nexObj, state.selectionBus);
    end
end


% ── Helpers ──────────────────────────────────────────────────────────────────

function restoreCollector(nexObj, serial)
    if isempty(serial) || isempty(fieldnames(serial)), return; end
    if isempty(nexObj.collector), return; end
    fields = fieldnames(serial);
    for i = 1:numel(fields)
        f     = fields{i};
        saved = serial.(f);
        if ~isfield(nexObj.collector, f), continue; end
        live = nexObj.collector.(f);
        if isa(live, 'nexObj_selectionBus') && isstruct(saved)
            applyBusSelections(live, saved);
        elseif isstruct(live) && isstruct(saved)
            sfields = fieldnames(saved);
            for j = 1:numel(sfields)
                sf = sfields{j};
                nexObj.collector.(f).(sf) = saved.(sf);
            end
        elseif isstring(saved) || ischar(saved) || isnumeric(saved)
            nexObj.collector.(f) = saved;
        end
    end
end

function restoreSelectionBus(nexObj, sbSerial)
    busNames = fieldnames(sbSerial);
    for i = 1:numel(busNames)
        bn = busNames{i};
        if ~isfield(nexObj.selectionBus, bn), continue; end
        applyBusSelections(nexObj.selectionBus.(bn), sbSerial.(bn));
    end
end

function applyBusSelections(bus, selMap)
    slots = fieldnames(selMap);
    for i = 1:numel(slots)
        s   = slots{i};
        tgt = string(selMap.(s));
        if ~isfield(bus.selKeys, s), continue; end
        avail = string(bus.selKeys.(s));
        idx   = find(avail == tgt, 1);
        if ~isempty(idx)
            bus.selections.(s) = idx;
            if isfield(bus.listBoxes, s) && ~isempty(bus.listBoxes.(s))
                bus.listBoxes.(s).Value = idx;
            end
        end
    end
end
