function categories = nexOp_listCategories(nexon)
    sl  = nexOp_listCategories_sessionLabel(nexon);
    if isfield(nexon.console.BASE.DTS,"signal_types")
        var = nexOp_listCategories_signals(nexon);
    else
        var = [];
    end
    vr  = nexOp_listCategories_var(nexon);   % direct manifest scalar task-var columns
    h5  = nexOp_listCategories_h5(nexon);

    % Remove h5 entries whose bare key already appears in sl / var / vr lists,
    % so the same measurement never shows up under two different prefixes.
    if ~isempty(h5)
        existing = bareKeys([sl(:); var(:); vr(:)]);
        h5 = h5(~ismember(bareKeys(h5), existing));
    end

    categories = [sl(:); var(:); vr(:); h5(:)];
end

function keys = bareKeys(cats)
    if isempty(cats)
        keys = string.empty(0,1);
        return;
    end
    parts = cellfun(@(c) strsplit(c,'--'), cellstr(cats), 'UniformOutput', false);
    keys  = string(cellfun(@(p) p{end}, parts, 'UniformOutput', false));
end