function TF = dtsIO_readTF_category(dataObj, category, idxSel)
    categoryParts = split(string(category), "--");
    categoryLabel = char(categoryParts(1));
    categoryID    = categoryParts(2);
    switch categoryLabel
        case "sessionLabel"
            TF = dtsIO_readVar(dataObj, categoryLabel, idxSel);
            TF = cellfun(@(var) parseSessionLabel(convertCharsToStrings(var), categoryID), TF, "UniformOutput", true);
        case "var"
            TF = dtsIO_readVar(dataObj, categoryID, idxSel);
        case "h5"
            % Read per-trial values from HDF5 — numeric or string.
            % dataObj may be a DTS table or a nexon handle — unwrap if needed.
            if istable(dataObj)
                DTS = dataObj;
            else
                DTS = dataObj.console.BASE.DTS;
            end
            sel = [];
            if ~(ischar(idxSel) && strcmp(idxSel, ':'))
                sel = idxSel;
            end
            raw = dtsIO_readTFH5(DTS, char(categoryID), sel, 'simple');
            % Auto-detect string vs numeric content
            nonEmpty = raw(~cellfun('isempty', raw));
            if ~isempty(nonEmpty) && (ischar(nonEmpty{1}) || isstring(nonEmpty{1}))
                TF = strings(numel(raw), 1);
                for ri = 1:numel(raw)
                    if ~isempty(raw{ri}), TF(ri) = string(raw{ri}); end
                end
            else
                TF = cellfun(@(c) scalarOrNaN(c), raw);
            end
    end
end

function v = scalarOrNaN(c)
    if isnumeric(c) && isscalar(c)
        v = double(c);
    else
        v = NaN;
    end
end