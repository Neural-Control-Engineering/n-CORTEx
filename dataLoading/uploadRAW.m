function uploadRAW(params, dataDir, sessionLabel, isDelete)
    dataFields = fieldnames(dataDir);
    % MOVE SLRT TO FRONT
    dataFields = flip(move2front(string(dataFields),"SLRT"));
    % CAMERA case (compile params for mp4 conversion)
    if any(contains(dataFields,"CAMERA"))
        try
            camTable = compileCamParams(params.camera);
        catch e
            disp(e)
            dataFields = dataFields(~ismember(dataFields,"CAMERA"));
        end
    end
    for i = 1:length(dataFields)        
        dataField = dataFields(i);
        if ~strcmp(dataField,"local") && ~strcmp(dataField,"cloud")
            dfLocal = dataDir.(dataField).local;
            dfCloud = dataDir.(dataField).cloud;
            % dfCloud = cloudDir;
            if ~isempty(dfLocal)
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
                                % % zip each camera-associated (DEPRECATED)
                                % localZip = fullfile(dfLocal,relPath,localItem);
                                % zip(sprintf("%s.zip",localZip),localZip);
                                % localPath = fullfile(sessPath,sprintf("%s.zip",localItem));                                
                                % CONVERT TO MP4
                                localPath = fullfile(sessPath,localItem);                                                                
                                camParams = camTable(contains(camTable.target,strrep(relPath,"/","")),:);
                                camFS = camParams.FS;                               
                                png2mp4Path = fullfile(params.paths.nCORTEx_repo,"postProc","png2mp4.sh");                                
                                ffmCmd = sprintf("%s %d %s", png2mp4Path, camFS, localPath);              
                                setenv('LD_PRELOAD', '/usr/lib/x86_64-linux-gnu/libstdc++.so.6');
                                system(ffmCmd);                                
                                rmdir(localPath,"s") % cleanup
                                % ZIP                
                                localZip = fullfile(dfLocal,relPath,localItem);
                                zip(sprintf("%s.zip",localZip), sprintf("%s.mp4",localPath));
                                % MOVE TO CLOUD
                                % % % movefile(localPath,fullfile(dfCloud,relPath,sprintf("%s.zip",localItem)),'f');
                                movefile(sprintf("%s.zip",localPath),fullfile(dfCloud,relPath),'f');
                                delete(sprintf("%s.mp4",localPath));
                            else
                                movefile(localPath,fullfile(dataDir.(dataField).cloud,relPath),'f');
                            end
                            
                            
                            % copyfile(localPath,fullfile(dataDir.(dataField).cloud,relPath,sessionLabel),'f')
                        end                
                    end                                 
                end        
            end
        end
    end
end