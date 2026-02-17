function categories = nexOp_listCategories_signals(nexon)
    allSignalTypes = nexon.console.BASE.DTS.signal_types;
    categories = cellfun(@(signalTypes) nexTract_signalTypeCategories(signalTypes), allSignalTypes, "UniformOutput", false);
    % extract unique categories
    categories = unique(cat(1, categories{:}));   
    categories = arrayfun(@(c) sprintf("var--%s",c),categories,"UniformOutput",true);
end