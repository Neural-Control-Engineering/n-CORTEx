function TF =  nexOp_compileTF(nexObj, idxSel)
    nexon = nexObj.nexon;    
    %% RETRIEVAL
    dfID = nexObj.dfID_source;
    if isempty(idxSel)
        S = nex_returnSelectionMask(nexon.console.BASE.controlPanel.averagingSelection);
        idxSel = nex_applySelectionMask(nexon.console.BASE.DTS, S);            
    end
    TF = dtsIO_readTF(nexon, dfID, idxSel);        
    fprintf("compiling %d samples \n", height(TF));
    %% DROP EMPTY 
    is_empty_TF = cellfun(@(DF) isempty(DF.df), TF, "UniformOutput", true);
    TF = TF(~is_empty_TF);
    %% ALIGNMENT (align all samples by '0' given preBuffLen)
    try
        S_slrt = nex_returnSelectionMask(nexObj.nexon.console.SLRT.signals.eventAlignmentSelection);
        alignColTags = split(S_slrt.events,"_");
        % tColID = sprintf("%s_aligned_%s_time",alignColTags(1),alignColTags(2));
        % tColID
        % tCol_slrt = nexObj.nexon.console.BASE.DTS.(tColID)(idxSel);
        fs_slrt = nexObj.nexon.console.SLRT.signals.UserData.Fs;
        t_preBuff = nexObj.UserData.preBufferLen;
        % TF_aligned = nexOp_eventAlignTF(TF, tCol_slrt, fs_slrt, t_preBuff);
        ID_sample_event = alignColTags(1);
        TF_sampleEvent = nexon.console.BASE.DTS.(ID_sample_event);
        TF_sampleEvent = TF_sampleEvent(idxSel);
        TF_sampleEvent = TF_sampleEvent(~is_empty_TF);
        TF_aligned = cellfun(@(DF, sample_event) {nexOp_eventAlignDF(DF, sample_event, fs_slrt, t_preBuff, 1)}, TF, TF_sampleEvent);
    catch e
        disp(getReport(e))
        TF_aligned = TF;
    end
    %% POOLING
    % ptr = nexObj.DF_postOp.ptr;
    % pm = nexObj.pMap;
    % TF_pooled = cellfun(@(DF) nexOp_poolAxes(pm, DF, ptr), TF_aligned, "UniformOutput",false);
    %% RESULT
    TF = TF_aligned;

end