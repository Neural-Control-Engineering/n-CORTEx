function nexOp_sBus_alignItems2ax(sBus_items)
    % on change in observable 'ax' (relatvie to a nexDF), update selection
    % items concerning dataframe axes (specific method for
    % nexObj_categorical)
    nexObj = sBus_items.Parent;
    sBus_categories = sBus_items.Children.sbus;
    S_items = nex_returnSelectionMask(sBus_items);
    S_categories = nex_returnSelectionMask(sBus_categories);
    % get all axis-associated selection lists 
    T_categories = struct2table(S_categories);
    P_categories = T_categories.Properties.VariableNames;
    idx_axCols = find(contains(T_categories{1,:},"ax--"));
    P_axCategories = convertCharsToStrings(P_categories(idx_axCols));
    ID_axCategories = T_categories{1,idx_axCols};
    % for each axis-associated category, update selection bus items to
    % reflect new DF_pooled ax
    for i = 1:length(P_axCategories)
        axCategory = P_axCategories(i);
        axID = ID_axCategories(i);
        axField = split(axID,"--"); axField = axField(end);
        newAx = nexObj.DF_postOp.ax.(axField);                
        % assign to (update) String property
        sBus_items.selKeys.(axCategory) = newAx;
        sBus_items.listBoxes.(axCategory).Value=1; % reset selection index
        sBus_items.listBoxes.(axCategory).String = newAx;                  
        sBus_items.listBoxes.(axCategory).Max=length(newAx);
    end
end