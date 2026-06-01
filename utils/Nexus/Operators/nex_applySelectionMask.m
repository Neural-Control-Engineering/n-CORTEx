function selCond = nex_applySelectionMask(DTS, S)    
    labelSelKeys = fieldnames(S);    
    % selCond = [1:height(DTS)]';
    selCond = true(height(DTS),1);
    for i = 1:length(labelSelKeys)
        key = labelSelKeys{i};
        keySel = S.(key);        
        % depending on key, isolate datastore column
        % categoryType = dtsIO_classifyCategory(DTS, key);        
        % read TF by category
        % prepare categoryLabel (find var type and append; 'var' for table var and 'sessionLabel' for sessionLabel-nested var)
        categoryType = dtsIO_classifyCategory(DTS, key);
        category = sprintf("%s--%s", categoryType,key);
        TF = dtsIO_readTF_category(DTS, category, ':');
        matchingRows = dtsIO_findMatchingRows(keySel, TF);
        
        % selCond = (selCond &  matchingRows);   

        try
            selCond = (selCond &  matchingRows);   
        catch
            fprintf("WARNING: %s could not be included in the intersection \n",key);
        end
    end
end