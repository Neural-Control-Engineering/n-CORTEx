function TF =  nexOp_compileTF(nexObj, idxSel)
    nexon = nexObj.nexon;
    %% RETRIEVAL
    dfID = nexObj.dfID_source;
    if isempty(idxSel)
        S = nex_returnSelectionMask(nexon.console.BASE.controlPanel.averagingSelection);
        idxSel = nex_applySelectionMask(nexon.console.BASE.DTS, S);            
    end
    TF = dtsIO_readTF(nexon, dfID, idxSel);        
    %% DROP EMPTY 
    is_empty_TF = cellfun(@(DF) isempty(DF.df), TF, "UniformOutput", true);
    TF = TF(~is_empty_TF);
    %% ALIGNMENT (testing)
    try
        S_slrt = nex_returnSelectionMask(nexObj.nexon.console.SLRT.signals.eventAlignmentSelection);
        alignColTags = split(S_slrt.events,"_");
        tColID = sprintf("%s_aligned_%s_%s_time",alignColTags(1),alignColTags(2),alignColTags(3));
        % tColID
        tCol_slrt = nexObj.nexon.console.BASE.DTS.(tColID)(idxSel);
        fs_slrt = nexObj.nexon.console.SLRT.signals.UserData.Fs;
        t_preBuff = nexObj.UserData.preBufferLen;
        TF_aligned = nexOp_eventAlignTF(TF, tCol_slrt, fs_slrt, t_preBuff);
    catch e
        disp(getReport(e))
        TF_aligned = TF;
    end
    %% POOLING
    ptr = nexObj.DF_postOp.ptr;
    pm = nexObj.pMap;
    TF_pooled = cellfun(@(DF) nexOp_poolAxes(pm, DF, ptr), TF, "UniformOutput",false);
    %% RESULT
    TF = TF_pooled;

end