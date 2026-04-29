function categories = nexOp_listCategories(nexon)
    sl  = nexOp_listCategories_sessionLabel(nexon);
    var = nexOp_listCategories_signals(nexon);
    h5  = nexOp_listCategories_h5(nexon);

    % Remove h5 entries whose bare key already appears in sl or var lists,
    % so the same measurement never shows up under two different prefixes.
    if ~isempty(h5)
        existing = bareKeys([sl; var]);
        h5 = h5(~ismember(bareKeys(h5), existing));
    end

    categories = [sl; var; h5];
end

function keys = bareKeys(cats)
    if isempty(cats)
        keys = string.empty(0,1);
        return;
    end
    parts = cellfun(@(c) strsplit(c,'--'), cellstr(cats), 'UniformOutput', false);
    keys  = string(cellfun(@(p) p{end}, parts, 'UniformOutput', false));
end