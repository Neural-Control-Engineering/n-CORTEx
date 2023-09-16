function cortex
    params = setBaseParams(struct);
    warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');
    % addpath(params.paths.nCORTEx_repo);
    % addpath(genpath(params.paths.nCORTEx_repo));
    nCORTEx_console;
end