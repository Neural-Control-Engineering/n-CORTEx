function LFP = extractEXT_LFP(SLRT, dataDir, session)

    
    imecPath = fullfile(dataDir.RAW.NPXLS.cloud,session,sprintf("%s_imec0",session));
    imecDir = dir(imecPath);        
    sortedTrigs = struct2table(imecDir);
    sortedTrigs = sortedTrigs.name;
    sortedTrigs = sortedTrigs(contains(sortedTrigs,"sorted"));
    numTrigs = size(sortedTrigs,1);
    for j = 1:numTrigs % visit each trial-gate              
        sortedFldr = sortedTrigs{j};
        % kSortPath = fullfile(imecPath,sortedFldr,"kilosort4");
        lfpPath = fullfile(strcat("\\?\",imecPath),sortedFldr);
        % AP = extAP(SLRT, kSortPath);
        LFP = extLFP(SLRT, lfpPath, j);
    end
    
end