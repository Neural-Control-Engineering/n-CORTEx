function uploadRAW(localRAW, cloudRAW, sessionLabel)
    dir(localRAW);
    rawMods = string(categorize(localRAW,'isDir'));
    for i = 1:length(rawMods)
        mod = rawMods{i};
        %  recurse and search for sessionlabel
        relPath = locateSessionFile(fullfile(localRAW,mod),sessionLabel);
        ss = size(relPath);
        for j = 1:ss(1)
            relPth = relPath(j);
            pthParts = split(relPth,filesep);
            brk = find(strcmp(pthParts,"nCORTExTmp"))
            savePth = join(pthParts(brk+1:end),filesep);
            % move to cloud
            sessionLabelFile = sprintf("%s.mat",sessionLabel)
            copyfile(fullfile(relPth,sprintf("",sessionLabelFile)),fullfile(cloudRAW,savePth,sessionLabelFile))
        end
    end
    realtimeLogDir_tmp = fullfile(tmpDir,"SLRT");
    realtimeLogFilePath = fullfile(realtimeLogDir_tmp,strcat(app.sessionParams.sessionLabel,".mat"));
    realtimeLogDir = fullfile(expDir_cloud,"SLRT");
    if exist(realtimeLogDir_tmp, "dir")
        if ~exist(realtimeLogDir,"dir")
            mkdir(realtimeLogDir);
        end
        movefile(realtimeLogFilePath,  realtimeLogDir, 'f')
    end  
end