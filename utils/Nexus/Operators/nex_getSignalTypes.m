function IDs_signals = nex_getSignalTypes(nexon)
    % agglomerate signal types over all trials stored 
    signal_types_all = nexon.console.BASE.DTS.signal_types;
    % for now choose first on with highest number of signals
    sigTypeSizes = cellfun(@(sigTypes) size(sigTypes), signal_types_all, "UniformOutput", false);
    sigTypeSizes = cat(1,sigTypeSizes{:});
    sz1 = sigTypeSizes(:,1);
    idx_max = find(sz1==max(sz1));
    idx_max = idx_max(1);
    % signal filter
    signal_types = signal_types_all{idx_max};
    idx_signals= cellfun(@(sigID) (strcmp(sigID,"signal")), signal_types(:,2), "UniformOutput", true);
    signalNames = signal_types(:,1);
    IDs_signals = convertCharsToStrings(signalNames(idx_signals));
end