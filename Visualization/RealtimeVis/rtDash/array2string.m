function str = array2string(arr)
    % Convert the numeric array to a formatted string
    % First, convert the array to a cell array of strings
    cellArray = arrayfun(@num2str, arr, 'UniformOutput', false);    
    % Join the cell array elements into a single string with ', ' separator
    joinedStr = strjoin(cellArray, ', ');    
    % Format the final string with square brackets
    str = ['[', joinedStr, ']'];
end