function sync = constructSync_slrt(SLRT)
   
    colNames_slrt = convertCharsToStrings(SLRT.Properties.VariableNames);
    syncLineRefCols = contains(colNames_slrt,"syncLine");
    syncLineCols = SLRT(:,colNames_slrt(syncLineRefCols==1));
    
    % construct sync lines
    sync=struct;
    for i=1:width(syncLineCols)
        syncLineCol = syncLineCols(:,i);
        syncName = syncLineCol.Properties.VariableNames{1};
        syncFreq = split(syncName,"_");
        syncFreq = syncFreq{2};        
        syncID = sprintf("sync_%s_slrt",syncFreq);
        sync.lines.(syncID) = struct;
        t_edges = [];
        for j=1:height(syncLineCol)
            subSync = syncLineCol{j,:}{1};
            t_edges = [t_edges, subSync.t_edges];
        end
        sync.lines.(syncID).t_edges = t_edges;
        sync.lines.(syncID).type = subSync.type;
        sync.lines.(syncID).ref = subSync.ref;
    end
end