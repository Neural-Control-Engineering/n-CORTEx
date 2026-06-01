function [categories] = nexOp_listCategories_sessionLabel(nexon)
    sessionLabels = nexon.console.BASE.DTS.sessionLabel;
    % extract label categories
    categories = cellfun(@(sessionLabel) nexTract_sessionLabelCategories(sessionLabel), sessionLabels, "UniformOutput", false);
    % items = cellfun(@(sessionLabel) nexTract_sessionLabelItems(sessionLabel), sessionLabels, "UniformOutput", false);
    % extract unique categories
    categories = unique(cat(1, categories{:}));
    categories = arrayfun(@(c) sprintf("sessionLabel--%s",c),categories,"UniformOutput",true);
end