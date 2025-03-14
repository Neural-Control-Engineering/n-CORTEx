function trialMask = recoverTrialMask(logsout)
    % trialMaskSignal = logsout.Data.cont_buttonStat;
    try
        trialMaskSignal = logsout.getElement("cont_buttonStat").Values.Data;
    catch e
        try
            trialMaskSignal = logsout.getElement("buttonStat").Values.Data;
        catch e
            trialMask = [];
            return
        end            
    end
    trialMaskSequence = diff(trialMaskSignal);
    trialMaskSequence = trialMaskSequence(trialMaskSequence > 0);
    if any(trialMaskSequence==3) % if there are any diffs of 3 (updated buttonStat)
        trialStartIdxs = find(trialMaskSequence == 1);
        trialStarts = trialMaskSequence(trialMaskSequence==1);
        trialMask = [];
        m=0;
        for i = 1:length(trialStarts)
            trialStartIdx = trialStartIdxs(i);
            if i < length(trialStarts) % if not at total end of series (EDGE CASE)
                if  trialMaskSequence(trialStartIdx+1) == 2% if value following start is 2
                    trialMask = [trialMask, m];            
                end            
            elseif i == length(trialStarts)
                try
                    if  trialMaskSequence(trialStartIdx+1) == 2% if value following start is 2
                        trialMask = [trialMask, m];            
                    end
                catch e
                    disp(getReport(e));
                end
            end
            m = m + 1;        
        end
    elseif any(trialMaskSequence==4)
        trialMask = 0;
    else
        risingEdges = diff(trialMaskSignal);
        risingEdges = risingEdges(risingEdges>0);        
        trialStartIdxs = find(trialMaskSequence == 1);
        trialStarts = trialMaskSequence(trialMaskSequence==1);
        trialMask = [];
        m=0;
        for i = 2:length(risingEdges) % ignore first rising edge
            risingEdgeVal = risingEdges(i);
            if risingEdgeVal == 1 % if not at total end of series (EDGE CASE)
                trialMask = [trialMask, m];                            
            end
            m = m + 1;        
        end
    end
end