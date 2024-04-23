function params = setHostParams(opts)

    %% Data Computer Registry
    if ~isfield(opts,'dataComputerIPs') opts.dataComputerIPs = struct; end
    % 
    if ~isfield(opts.dataComputerIPs,'bruker'); opts.dataComputerIPs.bruker = "128.59.87.69"; end
    if ~isfield(opts.dataComputerIPs,'primus'); opts.dataComputerIPs.primus = "128.59.150.93"; end
    if ~isfield(opts.dataComputerIPs,'perceptron'); opts.dataComputerIPs.perceptron = "128.59.130.93"; end

    %% PATH PRESETS        
    if ~isfield(opts,'paths'), opts.paths=struct; end    

    if ispc
        hostName = getenv('COMPUTERNAME');
        userName = getenv('USERNAME');
        if ~isfield(opts.paths,'stem'), opts.paths.stem=sprintf('C:\\Users\\%s',userName); end 
        % if ~isfield(opts.paths,'projDir_local'), opts.paths.projDir_local = fullfile(opts.paths.stem, "nCORTEx_local", opts.projectName); end
        % if ~exist(opts.paths.projDir_local, 'dir'), mkdir(opts.paths.projDir_local); end
        % if ~isfolder(opts.paths.projDir_local, 'dir'); replicateDirStructure(opts.paths.projDir_cloud, opts.paths.projDir_local); end
        if ~isfield(opts,'hostName'), opts.hostName=userName; end
    elseif isunix
        hostName = getenv('USER');
        if ~isfield(opts.paths,'stem'), opts.paths.stem=sprintf('/home/%s',hostName); end
        % if ~isfield(opts.paths,'projDir_local'), opts.paths.projDir_local = fullfile(opts.paths.stem, "nCORTEx_local", opts.projectName); end
        % if ~isfolder(opts.paths.projDir_local, 'dir'); replicateDirStructure(opts.paths.projDir_cloud, opts.paths.projDir_local); end    
        if ~isfield(opts,'hostName'), opts.hostName=hostName; end        
    end       

    if ~isfield(opts.paths,'projDir_local'), opts.paths.projDir_local = fullfile(opts.paths.stem, "nCORTEx_local", opts.projectName); end    
    if ~isfolder(opts.paths.projDir_local); replicateDirStructure(opts.paths.projDir_cloud, opts.paths.projDir_local); end

    % if ~isfield(opts.paths,'tempDir'), opts.paths.tempDir=fullfile(opts.paths.stem,'nCORTExTmp'); end
    % if ~exist(opts.paths.tempDir,'dir'), mkdir(opts.paths.tempDir); end
    
    if ~isfield(opts,'validationParams'), opts.validationParams = struct; end
    if ~isfield(opts.validationParams, 'stdThreshold'), opts.validationParams.stdThreshold = 0.1; end % std allowance in Hz
    if ~isfield(opts.validationParams, 'meanThreshold'), opts.validationParams.meanThreshold = 1; end % mean deviation allowance in Hz    
     
    params = opts;    
end