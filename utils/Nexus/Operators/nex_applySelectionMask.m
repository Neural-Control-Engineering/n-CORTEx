function selCond = nex_applySelectionMask(DTS, S)    
    labelSelKeys = fieldnames(S);    
    selCond = [1:height(DTS)]';
    for i = 1:length(labelSelKeys)
        key = labelSelKeys{i};
        keySel = S.(key);        
        matchingRows = cellfun(@(x) contains(x,keySel), DTS.sessionLabel);
        selCond = (selCond &  matchingRows);   
    end
end