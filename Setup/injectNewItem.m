function Items = injectNewItem(Items, newItem)
    disp(newItem);
    allItems = string(Items);
    allItems = allItems(~strcmp(allItems,"+"));
    allItems = allItems(~strcmp(allItems,"None"));
    allItems = [allItems, newItem];
    allItems = ["None", sort(allItems), {"+"}];
    Items = allItems;

end