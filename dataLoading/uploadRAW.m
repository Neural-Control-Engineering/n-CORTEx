function uploadRAW(dataDir, sessionLabel, isDelete)
    dataFields = fieldnames(dataDir);
    for i = 1:length(dataFields)
        dataField = dataFields{i};
        dfLocal = dataDir.(dataField).local;
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
                    movefile(localPath,fullfile(dataDir.(dataField).cloud,relPath),'f')
                    % copyfile(localPath,fullfile(dataDir.(dataField).cloud,relPath,sessionLabel),'f')
                end                
            end                                 
        end        
    end
end