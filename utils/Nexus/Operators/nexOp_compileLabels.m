function [Y, idxSel] = nexOp_compileLabels(nexObj, categories)

    % Global Filter
    S = nex_returnSelectionMask(nexObj.nexon.console.BASE.controlPanel.averagingSelection);
    idxSel = nex_applySelectionMask(nexObj.nexon.console.BASE.DTS, S);              
    
    class_nexObj = class(nexObj);
    if strcmp(class_nexObj, "nexObj_categorical")
    % if nexObj is categorical
        S_items = nex_returnSelectionMask(nexObj.selectionBus.items);    
        S_categories = nex_returnSelectionMask(nexObj.selectionBus.categories);
        S_merge = nexOp_mergeSelections_categorical(S_categories, S_items);
        idxSel = [idxSel & nex_applySelectionMask(nexObj.nexon.console.BASE.DTS, S_merge)];
    elseif isfield(nexObj.Partners,"ctg")
    % elseif nexObj has categorical partner
        S_items = nex_returnSelectionMask(nexObj.Partners.ctg.selectionBus.items);    
        S_categories = nex_returnSelectionMask(nexObj.Partners.ctg.selectionBus.categories);
        S_merge = nexOp_mergeSelections_categorical(S_categories, S_items);
        idxSel = [idxSel & nex_applySelectionMask(nexObj.nexon.console.BASE.DTS, S_merge)];
    % else (no subfilter)
    end
    
    Y = struct; % container for category items (across all selected samples)        
    for i = 1:length(categories)
        categoryID = string(categories{i});
        % categoryID = S_categories.(category);
        if ~contains(categoryID, "ax") && (~strcmp(categoryID,"None"))        
            TF_category = dtsIO_readTF_category(nexObj.nexon, categoryID, idxSel);            
            % Y = [Y, TF_category];
            categoryID = strrep(categoryID,"--","_");
            Y.(categoryID) = TF_category;
            % categoryProps = [categoryProps; strrep(categoryID,"--","_")];
            % selMatch = [selMatch & ismember(TF_category, S_items.(category))];
        end
    end    

    Y.index=find(idxSel==1);

    Y = struct2table(Y);

end