function uploadRAW(dataDir, sessionLabel, isDelete)
    dataFields = fieldnames(dataDir);
    % MOVE SLRT TO FRONT
    dataFields = move2front(string(dataFields),"SLRT");
    for i = 1:length(dataFields)
        dataField = dataFields(i);
        dfLocal = dataDir.(dataField).local;
        dfCloud = dataDir.(dataField).cloud;
        % dfCloud = cloudDir;
        sessionPaths = locateSessionFile(dfLocal,sessionLabel);
        for j = 1:size(sessionPaths,1)
            sessPath = sessionPaths(j);
            localItems = struct2table(dir(sessPath));
            localItems = string(localItems(contains(localItems.name,sessionLabel),:).name);
            relPath = split(sessPath,dataField);
            relPath = relPath(2);
            for k = 1:length(localItems)
                localItem = localItems(k);
                localPath = fullfile(sessPath,localItem);
                if isDelete == 1
                    if isfolder(localPath)
                        rmdir(localPath,"s");
                    elseif isfile(localPath)
                        delete(localPath);
                    end
                    
                else                    
                    cloudPath = fullfile(dataDir.(dataField).cloud);
                    buildPath(cloudPath);
                    if strcmp(dataField,"CAMERA")        
                        localZip = fullfile(dfLocal,relPath,localItem);
                        zip(sprintf("%s.zip",localZip),localZip);                    
                        localPath = fullfile(sessPath,sprintf("%s.zip",localItem));
                        movefile(localPath,fullfile(dfCloud,relPath,sprintf("%s.zip",localItem)),'f');
                    else
                        movefile(localPath,fullfile(dataDir.(dataField).cloud,relPath),'f');
                    end
                    
                    
                    % copyfile(localPath,fullfile(dataDir.(dataField).cloud,relPath,sessionLabel),'f')
                end                
            end                                 
        end        
    end
end