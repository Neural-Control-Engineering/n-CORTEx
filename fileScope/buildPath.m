function buildPath(filePath)
    % Split the file path into parts using filesep
    pathParts = strsplit(filePath, filesep);

    % Initialize the current path
    % currentPath = '';
    
    if ispc
        currentPath = fullfile(strcat(pathParts{1}),'/');
    else
        currentPath = fullfile(strcat('/',pathParts{1}),'/');
    end
    if ~exist(currentPath,'dir');  mkdir(currentPath); end

    % Iterate through the path parts and create each folder if it doesn't exist
    for i = 2:numel(pathParts)
        currentPath = fullfile(currentPath, pathParts{i});
        if ~exist(currentPath, 'dir')
            mkdir(currentPath);
        end
    end
end