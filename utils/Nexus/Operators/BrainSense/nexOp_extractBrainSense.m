function DTS_bsn = nexOp_extractBrainSense(DTS, rID)
    rColID = sprintf("LFP_%s", rID); % recording column
    DTS_bsn = [];
    for i = 1:height(DTS)
        entry = DTS(i,:);        
        T_r = entry.(rColID){1,1};
        if isempty(T_r)
            continue
        end
        try
            T_r = table2struct(T_r);
        catch
            keyboard
        end
        T_event = arrayfun(@(r) nexOp_BS2DF(r, rID), T_r, "UniformOutput",false);
        if size(T_event,1)>1
            % STAT_event = struct2table(cat(1,T_event{:}));
            T_event=cat(1,T_event{:});
        elseif isempty(T_event)
            continue
        else
            try
                T_event=T_event{1};           
            catch
                keyboard
            end
        end
        STAT_event=struct2table(T_event,"AsArray",true);
        % repeat entry cols for each row in STAT; append
        T_entry = removevars(entry,["LFP_event","LFP_brainSense","LFP_montage","Metadata","Hemisphere"]);
        V = repmat(T_entry, height(STAT_event),1);
        V.trialNumber=[1:height(STAT_event)]';
        STAT = [V, STAT_event];        
        STAT=nexOp_sessionLabel_brainSense(STAT);
        DTS_bsn = [DTS_bsn; STAT];
    end    

end