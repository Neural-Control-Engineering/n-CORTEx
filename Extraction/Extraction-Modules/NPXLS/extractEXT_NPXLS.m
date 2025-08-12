function NPXLS = extractEXT_NPXLS(SLRT, imecPath)
    % NPXLS
    imecPath = fullfile(params.paths.Data.RAW.NPXLS.cloud,session,sprintf("%s_imec0",session));
    imecDir = dir(imecPath);        
    sortedTrigs = struct2table(imecDir);
    sortedTrigs = sortedTrigs.name;
    sortedTrigs = sortedTrigs(contains(sortedTrigs,"sorted"));
    numTrigs = size(sortedTrigs,1);
    % accumulators
    % NPXLS = [];
    AP = [];
    LFP = [];
    for j = 1:numTrigs              
        sortedFldr = sortedTrigs{i};
        % kSortPath = fullfile(imecPath,sortedFldr,"kilosort4");
        % lfpPath = fullfile(imecPath,sortedFldr);
        npxls_path = fullfile(imecPath,sortedFldr);
        AP = extractEXT_AP(SLRT, npxls_path, j);
        LFP = extractEXT_LFP(SLRT, npxls_path, j);
    end
end