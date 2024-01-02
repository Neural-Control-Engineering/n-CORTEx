function numFrames = countFrames(path)
    % Get the list of items in the directory
    dirInfo = dir(path);
    % Count the number of items (excluding '.' and '..' entries)
    numFrames = length(dirInfo) - 2;
end