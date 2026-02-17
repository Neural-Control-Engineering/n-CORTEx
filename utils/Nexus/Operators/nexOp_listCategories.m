function categories = nexOp_listCategories(nexon)
    % subject label categories
    categories = nexOp_listCategories_sessionLabel(nexon);
    % slrt categories ('categorical' outcomes, affixes)
    categories = [categories; nexOp_listCategories_signals(nexon)];
end