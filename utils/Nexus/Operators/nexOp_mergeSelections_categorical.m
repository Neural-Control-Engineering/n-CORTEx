function S_merge = nexOp_mergeSelections_categorical(S_categories, S_items)
        ctgFields = convertCharsToStrings(fieldnames(S_categories));
        for i = 1:length(ctgFields); S_categories.(ctgFields(i)) = split(S_categories.(ctgFields(i)),"--"); end                    
        ctgKeys = structfun(@(s) s(end), S_categories);
        for i = 1:length(ctgFields); S_categories.(ctgFields(i)) = ctgKeys(i); end                    
        S_merge = outerjoinStructs(S_categories, S_items);
end