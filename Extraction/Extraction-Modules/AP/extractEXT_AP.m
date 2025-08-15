function AP = extractEXT_AP(SLRT, dataDir, session)
    % DONE - add session labels 
    % DONE - align spike times to all events 
    % DONE - merge spiking data and cluster info
     
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
        if ispc
            npxlsPath = fullfile(strcat("\\?\",imecPath),sortedFldr);
        elseif isunix
            npxlsPath = fullfile(strcat(imecPath),sortedFldr);
        end
        expmntLabel = strrep(string(sortedTrigs{j}),"_sorted","");
        [trigNum, gateNum] = decodeTrigger(expmntLabel);
        AP = [AP; extAP(SLRT, npxlsPath, trigNum+1)];
        % LFP = extLFP(SLRT, lfpPath);      
    end
    
end