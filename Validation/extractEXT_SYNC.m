function SYNC = extractEXT_SYNC(SLRT, dataDir, session)        
    imecPath = fullfile(dataDir.RAW.NPXLS.cloud,session,sprintf("%s_imec0",session));
    imecDir = dir(imecPath);        
    sortedTrigs = struct2table(imecDir);
    sortedTrigs = sortedTrigs.name;
    sortedTrigs = sortedTrigs(contains(sortedTrigs,"sorted"));
    numTrigs = size(sortedTrigs,1);
    AP = [];
    for j = 1:numTrigs % visit each trial-gate                     
        sortedFldr = sortedTrigs{j};
        % kSortPath = fullfile(imecPath,sortedFldr,"kilosort4");
        npxlsPath = fullfile(strcat("\\?\",imecPath),sortedFldr);
        load(fullfile(npxlsPath,"sync.mat"),'sync'); % time vectors and QC meta analysis for cross-device sync pulses    
        syncLine = sync.lines.sync_1Hz_imec;
        syncLine_nidq = sync.lines.sync_1Hz_nidq;
        syncLine.t_insert=syncLine_nidq.t_insert;
        syncLine_ref = SLRT.syncLine_1Hz_ext{j};        
        % syncOffsets = measureSyncOffsets(syncLine.t_edges, syncLine_ref.t_edges, syncLine.t_insert, syncLine_ref.t_insert, "world");
        figure; xline(syncLine.t_edges,"red"); hold on; xline(syncLine_ref.t_edges,"blue");
        xline(syncLine.t_insert,"green"); xline(syncLine_ref.t_insert,"yellow");
        hold off;
        % figure; plot(syncLine.t_edges, syncOffsets);
        title(sprintf("%d",j));
        % AP = [AP; extAP(SLRT, npxlsPath, j)];
        % LFP = extLFP(SLRT, lfpPath);
    end

end