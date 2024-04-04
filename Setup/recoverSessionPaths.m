function sessionPaths = recoverSessionPaths(hostName)
    % load nCORTEx cache
    % deref hostname
    % di0ps("recovering session paths")
    sessionPaths = struct;
    if isfile("Setup/nCORTExCache.mat")
       load("Setup/nCORTExCache.mat",'cache');
       hostFields = fieldnames(cache);
       if contains(hostFields,hostName)
           sessionPaths.modulePath = cache.(hostName).modulePath;
           sessionPaths.projectPath = cache.(hostName).projectPath;
       else
           cache.(hostName) = struct;
       end       
       save("Setup/nCORTExCache.mat",'cache')
    else
        sessionPaths = [];
        cache = struct;
        save("Setup/nCORTExCache.mat",'cache')
    end    
end