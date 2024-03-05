function dataStore = loadTall(location)
    if isempty(location)
        location = uigetdir;            
    end

    % Create a file datastore
    data = fileDatastore(location, 'ReadFcn', @(x) x);

    % Exclude 'desktop.ini' from the list of files
    files = data.Files;
    invalidFileIndex = strcmp(files, fullfile(location, 'desktop.ini'));
    files(invalidFileIndex) = [];
    
    % Create a new file datastore with the filtered list of files
    data = fileDatastore(files, 'ReadFcn', @(x) x);

    % Convert the file datastore to a tall datastore
    dataStore = datastore(data.Files);    
    dataStore = tall(dataStore);
end