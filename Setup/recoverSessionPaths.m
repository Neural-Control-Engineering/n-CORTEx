function sessionPaths = recoverSessionPaths(hostName)
    % load nCORTEx cache
    % deref hostname
    % di0ps("recovering session paths")
    sessionPaths = struct;
    if isfile("Setup/nCORTExCache.mat")
       load("Setup/nCORTExCache.mat",'cache');
       hostFields = fieldnames(cache);
       if any(contains(hostFields,hostName))
           sessionPaths.modulePath = cache.(hostName).modulePath;
           sessionPaths.projectPath = cache.(hostName).projectPath;
       else
           % first time seeing this host, return empty
           cache.(hostName) = struct;
           sessionPaths = [];
       end       
       save("Setup/nCORTExCache.mat",'cache')
    else
        sessionPaths = [];
        cache = struct;
        save("Setup/nCORTExCache.mat",'cache')
    end    
end