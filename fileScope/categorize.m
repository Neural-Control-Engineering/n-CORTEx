function items = categorize(location, pattern)
    % Return categorical array of items in a directory that match the given pattern

    % Get a list of all items in the directory
    dirInfo = dir(location);

    % Extract names of items
    itemNames = {dirInfo.name};
    isDir = {dirInfo.isdir};

    % Create a categorical array
    if pattern=="isDir"
        items = categorical(itemNames(cell2mat(isDir)==1));
        items = items(3:end);
    elseif pattern=="first_"
        items = split(cellstr(itemNames)',"_");
    else
        items = categorical(itemNames(contains(itemNames,pattern)));
    end
end