function mdlObj = mdlObj_fromState(state, Parent, Origin)
% Reconstruct a headless mdlObject subclass from a saved state struct.
%
%   mdlObj = mdlObj_fromState(state, Parent, Origin)
%
%   state  : struct produced by mdlObj.saveState()
%   Parent : the parent object (nexObj_ctg or manifest nexon) to wire up
%   Origin : the origin object (same as Parent for root nodes)
%
% The returned mdlObj is fully configured but has no fitted weights.
% Call mdlObj.loadFit(state.fitPath) after this to restore the model.

    % ── Construct the subclass (headless via nexon.settings.headless) ────────
    initFcn = str2func(state.className);

    % lda takes an extra predictorID arg; all others follow (Parent,Origin,dfID,headline)
    if strcmpi(state.modelID, 'lda')
        mdlObj = initFcn(Parent, Origin, state.dfID_source, [], state.headline);
    else
        mdlObj = initFcn(Parent, Origin, state.dfID_source, state.headline);
    end

    % ── Restore identification fields ────────────────────────────────────────
    mdlObj.fitPath = state.fitPath;
    if isfield(state, 'dfID_target') && ~isempty(state.dfID_target)
        mdlObj.dfID_target = state.dfID_target;
    end

    % ── Restore domain ───────────────────────────────────────────────────────
    if isfield(state, 'domain') && ~isempty(state.domain)
        fields = fieldnames(state.domain);
        for i = 1:numel(fields)
            mdlObj.domain.(fields{i}) = state.domain.(fields{i});
        end
    end

    % ── Restore cfg (generic — handles fitCfg, dmCfg, cvCfg, etc.) ─────────
    if isfield(state, 'cfg') && ~isempty(state.cfg)
        nex_restoreCfg(mdlObj.cfg, state.cfg);
    end

    % ── Restore collector selection values ───────────────────────────────────
    if isfield(state, 'collector') && ~isempty(state.collector)
        restoreCollector(mdlObj, state.collector);
    end
end


% ── Helpers ──────────────────────────────────────────────────────────────────

function restoreCollector(mdlObj, serial)
    if isempty(serial) || isempty(fieldnames(serial)), return; end
    if isempty(mdlObj.collector), return; end
    fields = fieldnames(serial);
    for i = 1:numel(fields)
        f       = fields{i};
        saved   = serial.(f);
        if ~isfield(mdlObj.collector, f), continue; end
        live = mdlObj.collector.(f);
        if isa(live, 'nexObj_selectionBus') && isstruct(saved)
            applyBusSelections(live, saved);
        elseif isstruct(live) && isstruct(saved)
            sfields = fieldnames(saved);
            for j = 1:numel(sfields)
                sf = sfields{j};
                mdlObj.collector.(f).(sf) = saved.(sf);
            end
        elseif isstring(saved) || ischar(saved) || isnumeric(saved)
            mdlObj.collector.(f) = saved;
        end
    end
end

function applyBusSelections(bus, selMap)
    % Set each slot in the bus to the saved value (matched by string).
    slots = fieldnames(selMap);
    for i = 1:numel(slots)
        s    = slots{i};
        tgt  = string(selMap.(s));
        if ~isfield(bus.selKeys, s), continue; end
        avail = string(bus.selKeys.(s));
        idx   = find(avail == tgt, 1);
        if ~isempty(idx)
            bus.selections.(s) = idx;
        end
    end
end
