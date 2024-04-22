function replicateDirStructure(sourceDir, targetDir)
    % Check if the source directory exists
    if ~isfolder(sourceDir)
        error('Source directory does not exist.');
    end
   
    % Ensure the target directory exists; create if it does not
    if ~isfolder(targetDir)
        mkdir(targetDir);
    end
   
    % Get a list of all items in the source directory
    items = dir(sourceDir);
   
    % Filter out the current and up-directory references ('.' and '..') and files
    dirs = items([items.isdir] & ~ismember({items.name}, {'.', '..'}) & ~startsWith({items.name},'.') & ~contains({items.name},'_g'));
   
    % Iterate through each subdirectory
    for i = 1:length(dirs)
        subdirName = dirs(i).name;
       
        % Construct the new source and target paths
        newSourceDir = fullfile(sourceDir, subdirName);
        newTargetDir = fullfile(targetDir, subdirName);
       
        % Create the subdirectory in the target location
        mkdir(newTargetDir);
        % newTargetDir
       
        % Recursively replicate the structure for this subdirectory
        replicateDirStructure(newSourceDir, newTargetDir);
    end
end