function buildPath(filePath)
    % Split the file path into parts using filesep
    pathParts = strsplit(filePath, filesep);

    % Initialize the current path
    currentPath = '';

    % Iterate through the path parts and create each folder if it doesn't exist
    for i = 1:numel(pathParts)
        currentPath = fullfile(currentPath, pathParts{i});
        if ~exist(currentPath, 'dir')
            mkdir(currentPath);
        end
    end
end