function TF = dtsIO_readTF_category(dataObj, category, idxSel)
    categoryParts = split(category,"--");
    categoryLabel = categoryParts(1);
    categoryID    = categoryParts(2);
    switch categoryLabel
        case "sessionLabel"
            TF = dtsIO_readVar(dataObj, categoryLabel, idxSel);
            TF = cellfun(@(var) parseSessionLabel(convertCharsToStrings(var), categoryID), TF, "UniformOutput", true);
        case "var"
            TF = dtsIO_readVar(dataObj, categoryID, idxSel);
        case "h5"
            % Read scalar-per-trial values from HDF5 and flatten to double vector.
            % idxSel ':' → all rows; otherwise pass through.
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
            % raw is {N×1} cell of scalar numeric arrays or [].
            % Flatten: missing trials → NaN (will not match any keySel value).
            TF = cellfun(@(c) scalarOrNaN(c), raw);
    end
end

function v = scalarOrNaN(c)
    if isnumeric(c) && isscalar(c)
        v = double(c);
    else
        v = NaN;
    end
end