function [cleanedArray] = removeEmptyOrNaNCells(cellArray, column)
    % removeEmptyOrNaNCells Removes rows with empty or NaN cells in a specified column
    % Input:
    %   cellArray - Input cell array
    %   column - Column index to check for empty or NaN values
    % Output:
    %   cleanedArray - Cell array with the specified rows removed

    % Check if the input column index is valid
    if column > size(cellArray, 2)
        error('Column index exceeds the number of columns in the cell array.');
    end

    % Create a logical index vector for rows to keep
    keepRows = ~cellfun(@isempty, cellArray(:, column)) & ...
               ~cellfun(@(x) all(isnumeric(x) & isnan(x)), cellArray(:, column));

    % Filter the cell array to keep only the desired rows
    cleanedArray = cellArray(keepRows, :);
end
