function items = nexOp_enumerateCategory(nexObj, category)    
    % list category items, given a category, if a nexObj is passed:
    % if nexObj is a standard interactive figure, and category is an
    % axis-type, first dereference using the ax handle of the nexObj
    % dataframe (postOperative)
    % if 'category' does not match an axis, check the global registry of
    % categories
    % try to deref DF axes first (search 1)
    category = convertCharsToStrings(split(category,"--")); category = category(end);
    try
        % search the dataframe axes first
        items = nexObj.DF_postOp.ax.(category);
    catch
        % deref registry second (search 2)
        switch class(nexObj)
            case "nexon"
                items = nexObj.console.BASE.registry.categories.(category);
            otherwise
                items = nexObj.nexon.console.BASE.registry.categories.(category);
        end       
    end
end