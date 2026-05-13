function IDs_events = nex_getEventTypes(nexon)
    signal_types_all = nexon.console.BASE.DTS.signal_types;
    sigTypeSizes = cellfun(@(s) size(s, 1), signal_types_all, "UniformOutput", true);
    idx_max = find(sigTypeSizes == max(sigTypeSizes), 1);
    signal_types = signal_types_all{idx_max};
    idx_events = cellfun(@(t) strcmp(t, 'event'), signal_types(:, 2), "UniformOutput", true);
    IDs_events = convertCharsToStrings(signal_types(idx_events, 1));
end
