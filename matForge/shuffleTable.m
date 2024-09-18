function shuffledTable = shuffleTable(T)
    % Get the number of rows in the table
    nRows = height(T);
    
    % Generate a random permutation of the row indices
    randIndices = randperm(nRows);
    
    % Rearrange the table rows according to the random indices
    shuffledTable = T(randIndices, :);
end