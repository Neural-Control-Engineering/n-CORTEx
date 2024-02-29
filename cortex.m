function cortex(method)
    % params = setBaseParams(struct);
    % system('./mountNEC.sh');
    % warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
    % addpath(params.paths.nCORTEx_repo);
    % addpath(genpath(params.paths.nCORTEx_repo));
    switch(method)
        case "extract"
            nCORTEx_extraction;
        case "acquire"
            nCORTEx_acquisition;
    end    
end