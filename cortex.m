function cortex(method)
    % params = setBaseParams(struct);
    % system('./mountNEC.sh');
    % warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
    % addpath(params.paths.nCORTEx_repo);
    % addpath(genpath(params.paths.nCORTEx_repo));
    switch(method)
        case "target"
            nCORTEx_target;
        case "host"
            nCORTEx_host;
    end    
end