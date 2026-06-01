function dfCol_trim = nexOp_trimDfCol(dfCol)
    SZ = cellfun(@(x) size(x), dfCol, "UniformOutput", false);
    SZ = cat(1,SZ{:});
    sz_min = num2cell(min(SZ, [], 1));
    % for each size, trim
    % slice
    slice = repmat({':'},1,length(sz_min));
    slice = cellfun(@(idx, lim) [1:lim], slice, sz_min, "UniformOutput", false);
    dfCol_trim = cellfun(@(x) x(slice{:}), dfCol, "UniformOutput", false);
end