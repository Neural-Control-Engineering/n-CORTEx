function uploadRAW_CAMERA(params, dfCloud, sessPath, localItem, relPath)
    % % zip each camera-associated (DEPRECATED)
    % localZip = fullfile(dfLocal,relPath,localItem);
    % zip(sprintf("%s.zip",localZip),localZip);
    % localPath = fullfile(sessPath,sprintf("%s.zip",localItem));                                
    % CONVERT TO MP4
    localPath = fullfile(sessPath,localItem); 
    camTable=params.camTable;
    camParams = camTable(contains(camTable.target,strrep(relPath,"/","")),:);
    camFS = camParams.FS;
    frameDim.width = camParams.spinParams.Width;
    frameDim.height = camParams.spinParams.Height;    
    pixelFormat = camParams.spinParams.PixelFormat;    
    switch pixelFormat
        case "BayerRG8"
            frameDim.channels=1;            
        case "Mono8"
            frameDim.channels=1;
        otherwise
            frameDim.channels=1;
    end
    frameDim.byteDepth = 1; % currently defaulting to unit8
    % numFrames = cameraCtrl_countFrames(frames,frameDim);
    % convert binary to avi
    
    outputFile = sprintf("%s.mp4",localItem);
    outputFile = fullfile(localPath,outputFile);
    frameDir = fullfile(sessPath, localItem);
    % cameraCtrl_convertBinaryFrames2mp4(frameDir, outputFile, camFS, "BayerRG8");
    cameraCtrl_convertBinaryFrames2mp4(frameDir, frameDim, outputFile, camFS, pixelFormat);
    
    % STOP HERE
    % png2mp4Path = fullfile(params.paths.nCORTEx_repo,"postProc","png2mp4.sh");                                
    % ffmCmd = sprintf("%s %d %s", png2mp4Path, camFS, outputFile);              
    % setenv('LD_PRELOAD', '/usr/lib/x86_64-linux-gnu/libstdc++.so.6');
    % system(ffmCmd);   
    % % if conversion successful, remove pngs
    % if isfile(sprintf("%s.mp4",localPath))
    %     rmdir(localPath,"s") % cleanup
    % else
    %     error("png to mp4 conversion for session: %s failed",localItem)
    % end
    % ZIP                
    % localZip = fullfile(dfLocal,relPath,localItem);
    % localZip = fullfile(dfLocal,relPath,localItem);
    % zip(sprintf("%s.zip",localZip), sprintf("%s.mp4",localPath));
    localZip = fullfile(localPath,localItem);
    zip(sprintf("%s.zip",localZip), sprintf("%s.mp4",localZip));
    % MOVE TO CLOUD
    % % % movefile(localPath,fullfile(dfCloud,relPath,sprintf("%s.zip",localItem)),'f');
    movefile(sprintf("%s.zip",localZip),fullfile(dfCloud,relPath),'f');
    delete(sprintf("%s.mp4",localZip));
    % delete working directory
    rmdir(localPath,"s");
end