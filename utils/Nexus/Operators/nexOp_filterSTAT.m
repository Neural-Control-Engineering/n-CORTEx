function STAT = nexOp_filterSTAT(STAT, S_sel)
% Filter STAT rows to those whose ax_* columns match S_sel.
%
% S_sel : struct — fieldnames are ax_*-prefixed STAT column names;
%         values are string/numeric arrays of allowed values.
%         Built by outerjoinStructs(S_categories, S_items) in drawCanvas
%         (-- replaced with _ by outerjoinStructs; "None" slots removed
%         by rmfield before this call).

    if isempty(S_sel) || isempty(fieldnames(S_sel))
        return;
    end

    fields = string(fieldnames(S_sel))';
    statCols = string(STAT.Properties.VariableNames);
    mask = true(height(STAT), 1);

    for f = fields
        vals = S_sel.(f);
        % skip empty or unset slots
        if isempty(vals) || isequal(vals, "") || isequal(vals, "")
            continue;
        end
        % skip if STAT does not carry this column
        if ~ismember(f, statCols)
            continue;
        end
        col = STAT.(f);
        if iscell(col)
            col = string(col);
        end
        mask = mask & ismember(col, string(vals));
    end

    STAT = STAT(mask, :);
end
