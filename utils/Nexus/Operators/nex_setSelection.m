function nex_setSelection(target, key, vals)
% Programmatically set an item selection by key name and value(s).
% Companion to nex_returnSelectionMask / nex_applySelectionMask.
%
%   target : one of —
%     nexObj_selectionBus          direct key lookup (e.g. averagingSelection itself)
%     nexObj_controlPanel          routes to target.averagingSelection
%     nexObj_categorical (or any   finds slot in selectionBus.categories whose current
%       nexObj with .selectionBus) selection matches key, then sets items for that slot
%
%   key  : string — key in selKeys (averagingSelection) or catID (categorical).
%          Both "sessionLabel--subj" and "sessionLabel_subj" forms accepted.
%
%   vals : string or string array of values to select.
%          [] or "" → selects all available items (no filter).
%
% Examples:
%   % categorical — filter to two subjects
%   nex_setSelection(nexObj_ctg, 'sessionLabel_subj', ["10191_20250814","0092_20538323"])
%
%   % controlPanel — filter averaging to one phase
%   nex_setSelection(nexon.console.BASE.controlPanel, 'phase', "baseline")
%
%   % averagingSelection bus directly
%   nex_setSelection(nexon.console.BASE.controlPanel.averagingSelection, 'subj', "10191_20250814")

    if isa(target, 'nexObj_selectionBus')
        selBusSetByValue(target, key, vals);
        return;
    end

    % controlPanel-style target: has .averagingSelection bus
    hasAvgSel = false;
    try, hasAvgSel = isa(target.averagingSelection, 'nexObj_selectionBus'); catch, end
    if hasAvgSel
        selBusSetByValue(target.averagingSelection, key, vals);
        return;
    end

    % categorical-style target: has .selectionBus.categories + .items
    hasCatBus = false;
    try
        hasCatBus = isstruct(target.selectionBus) && ...
                    isfield(target.selectionBus, 'categories') && ...
                    isfield(target.selectionBus, 'items');
    catch, end
    if hasCatBus
        slot = findCategorySlot(target.selectionBus.categories, key);
        if isempty(slot)
            warning('nex_setSelection: category "%s" not found in any active slot.', key);
            return;
        end
        selBusSetByValue(target.selectionBus.items, slot, vals);
        return;
    end

    warning('nex_setSelection: unrecognised target type "%s".', class(target));
end

% ── Helpers ───────────────────────────────────────────────────────────────

function selBusSetByValue(selBus, key, vals)
% Set selBus.selections.(key) by matching values; sync listbox if present.
    if ~isfield(selBus.selKeys, key)
        warning('nex_setSelection: key "%s" not found in selectionBus.', key);
        return;
    end
    avail = string(selBus.selKeys.(key));
    vals  = string(vals);
    if isempty(vals) || all(vals == "" | vals == "None")
        idxs = 1:numel(avail);   % empty request → select all (no filter)
    else
        idxs = find(ismember(avail, vals));
        if isempty(idxs)
            warning('nex_setSelection: none of [%s] found for key "%s". Available: [%s]', ...
                strjoin(vals, ', '), key, strjoin(avail, ', '));
            return;
        end
    end
    selBus.selections.(key) = idxs;
    % Sync UI listbox when one is attached (headless: listBoxes field absent or empty)
    try
        if isfield(selBus.listBoxes, key)
            lb = selBus.listBoxes.(key);
            if ~isempty(lb) && isvalid(lb)
                lb.Value = idxs;
            end
        end
    catch, end
end

function slot = findCategorySlot(catBus, catID)
% Return the slot name (C1, C2, ...) whose current selection matches catID.
% Returns '' when no active slot holds catID.
    slot   = '';
    normID = normalizeCatID(catID);
    slots  = fieldnames(catBus.selKeys);
    for i = 1:numel(slots)
        s      = slots{i};
        selIdx = catBus.selections.(s);
        if isempty(selIdx), continue; end
        if ~isscalar(selIdx), selIdx = selIdx(1); end
        avail  = string(catBus.selKeys.(s));
        if selIdx < 1 || selIdx > numel(avail), continue; end
        if strcmp(normalizeCatID(avail(selIdx)), normID)
            slot = s;
            return;
        end
    end
end

function id = normalizeCatID(id)
% Canonicalise to "type--key" form so "sessionLabel_subj" and
% "sessionLabel--subj" both resolve to the same string.
    id = char(id);
    prefixes = {'sessionLabel', 'h5', 'var'};
    for i = 1:numel(prefixes)
        p = prefixes{i};
        if strncmp(id, [p '_'], numel(p) + 1)
            id = [p '--' id(numel(p) + 2 : end)];
            return;
        end
    end
end
