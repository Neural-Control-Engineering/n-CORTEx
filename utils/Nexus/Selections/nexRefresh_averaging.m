function nexRefresh_averaging(nexObj)
% Refresh an existing averaging selection bus in place from the current DTS.
%
% Mirrors the router refresh in Nexon.appendToDTS: recompute the candidate
% value lists (subj/phase/date/site + signal tags) and push them into the
% LIVE bus — updating each key's selKeys and its listbox (String/Max) while
% preserving the user's current selection BY VALUE, so newly added trials
% (new subject/phase/date, new signal tags) become selectable without
% rebuilding the bus, its listboxes, or dropping existing selections.
%
% New keys (a signal tag never seen before) are added to selKeys; their
% listbox is only created by nexObj_listCfgPanel at figure build, so a brand
% new KEY won't render until the panel is rebuilt — new VALUES on existing
% keys update live.
    bus = nexObj.averagingSelection;
    if isempty(bus), return; end
    avgingDict = nexSelect_averagingDict(nexObj.nexon);
    keyFields  = fieldnames(avgingDict);
    for i = 1:numel(keyFields)
        key     = keyFields{i};
        newVals = convertCharsToStrings(avgingDict.(key));

        % Capture currently selected values (indices into the OLD selKeys).
        selVals = strings(0,1);
        if isfield(bus.selKeys, key)
            oldVals = convertCharsToStrings(bus.selKeys.(key));
            if isfield(bus.selections, key)
                idx = bus.selections.(key);
                idx = idx(idx >= 1 & idx <= numel(oldVals));
                selVals = oldVals(idx);
            end
        end

        % Remap selection to the new value list by VALUE; default to first.
        newSel = find(ismember(newVals, selVals));
        if isempty(newSel), newSel = 1; end

        bus.selKeys.(key)    = newVals;
        bus.selections.(key) = newSel;

        % Update the listbox in place when wired to the UI.
        if isfield(bus.listBoxes, key) && ~isempty(bus.listBoxes.(key)) ...
                && isvalid(bus.listBoxes.(key))
            lb        = bus.listBoxes.(key);
            lb.String = newVals;
            lb.Max    = max(1, numel(newVals));
            lb.Value  = newSel;
        end
    end
end
