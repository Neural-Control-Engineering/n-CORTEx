function [sync, sessionDetails] = constructSync_slrt(SLRT, trigNum)   
    % for each trial-gate, re-concatenate the previously segmented trials
    % to reconstruct the synclines for that recording segment
    trialGates = cell2mat(SLRT.("trial-gate"));
    SLRT_trig = SLRT(trialGates==trigNum,:);
    colNames_slrt = convertCharsToStrings(SLRT_trig.Properties.VariableNames);
    syncLineRefCols = contains(colNames_slrt,"syncLine");
    syncLineCols = SLRT_trig(:,colNames_slrt(syncLineRefCols==1));
    sessionDetails.t = trigNum;
    sessionDetails.sessionLabel = SLRT_trig.session_label{1};
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
            if j == 1
                t_insert = subSync.t_insert;
            end
            t_edges = [t_edges, subSync.t_edges];
        end
        sync.lines.(syncID).t_insert = t_insert;
        sync.lines.(syncID).t_edges = t_edges;
        sync.lines.(syncID).type = subSync.type;
        sync.lines.(syncID).ref = subSync.ref;
    end
end