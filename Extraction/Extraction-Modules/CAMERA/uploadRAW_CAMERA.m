function uploadRAW_CAMERA(params, sessPath, sessionLabel)
    % % zip each camera-associated (DEPRECATED)
    % localZip = fullfile(dfLocal,relPath,localItem);
    % zip(sprintf("%s.zip",localZip),localZip);
    % localPath = fullfile(sessPath,sprintf("%s.zip",localItem));                                
    % CONVERT TO MP4
    localPath = fullfile(sessPath,localItem);                                                                
    camParams = camTable(contains(camTable.target,strrep(relPath,"/","")),:);
    camFS = camParams.FS;      
    % convert binary to avi
    outputFile = sprintf("%s,mp4",sessionLabel);
    outputFile = fullfile(localPath,outputFile);
    frameDir = fullfile(sessPath, sessionLabel);
    cameraCtrl_convertBinaryFrames2mp4(frameDir, outputFile, camFS);

    png2mp4Path = fullfile(params.paths.nCORTEx_repo,"postProc","png2mp4.sh");                                
    ffmCmd = sprintf("%s %d %s", png2mp4Path, camFS, localPath);              
    setenv('LD_PRELOAD', '/usr/lib/x86_64-linux-gnu/libstdc++.so.6');
    system(ffmCmd);   
    % if conversion successful, remove pngs
    if isfile(sprintf("%s.mp4",localPath))
        rmdir(localPath,"s") % cleanup
    else
        error("png to mp4 conversion for session: %s failed",sessionLabel)
    end
    % ZIP                
    localZip = fullfile(dfLocal,relPath,localItem);
    zip(sprintf("%s.zip",localZip), sprintf("%s.mp4",localPath));
    % MOVE TO CLOUD
    % % % movefile(localPath,fullfile(dfCloud,relPath,sprintf("%s.zip",localItem)),'f');
    movefile(sprintf("%s.zip",localPath),fullfile(dfCloud,relPath),'f');
    delete(sprintf("%s.mp4",localPath));
end