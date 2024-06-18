function LFP = extractEXT_LFP(SLRT, dataDir)

    imecPath = fullfile(dataDir.RAW.NPXLS.cloud,session,sprintf("%s_imec0",session));
    imecDir = dir(imecPath);        
    sortedTrigs = struct2table(imecDir);
    sortedTrigs = sortedTrigs.name;
    sortedTrigs = sortedTrigs(contains(sortedTrigs,"sorted"));
    numTrigs = size(sortedTrigs,1);
    for j = 1:numTrigs              
        sortedFldr = sortedTrigs{i};
        kSortPath = fullfile(imecPath,sortedFldr,"kilosort4");
        lfpPath = fullfile(imecPath,sortedFldr);
        % AP = extAP(SLRT, kSortPath);
        LFP = extLFP(SLRT, lfpPath);
    end
    
end