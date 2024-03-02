function expmntData_ext = extractJOLT(params, sessionsToExtract, Q)

    expmntData_ext.SLRT.trialNum = {};
    expmntData_ext.SLRT.stimTrace_raw = {};
    expmntData_ext.SLRT.stimTrace_lowess = {};
    expmntData_ext.SLRT.responseDelay = {};
    expmntData_ext.SLRT.responseThreshold = {};
    expmntData_ext.SLRT.pawSide = {};
    expmntData_ext.SLRT.QC = {};
    expmntData_ext.SLRT.sessionType = {};
    
    expmntData_ext.LFP = [];
    sessions = sessionsToExtract.sessions;
    for i = 1:length(sessions)
        session = sessions{i};
        % function to return npxls acquisition times 
        % relative to user action (e.g. Button presses)      
        
        % LOAD DATA OF INTEREST
        SLRT = loadEXT_SLRT(params, session);
        LFP = loadEXT_LFP(params, session);
    
        %% PROCESS SLRT LOG
        rtData = SLRT.data;
        rtSession = SLRT.meta.sessionLabel;
        % load stim trace                           
        stim_filt = get(rtData,"stim_filt");
        stim_filt = stim_filt.Values;
        stim_raw = get(rtData,"stim_raw");
        stim_raw = stim_raw.Values;    
        % acquisition timing
        acqPulse = get(rtData,"npxlsAcq_out");
        acqPulse = acqPulse{1}.Values;
        acqStarts = diff(acqPulse.Data);
        riseIdx = find(acqStarts>0)+1;
        cutoff = find(rtData,"npxlsAcqCutoff");
        if ~isempty(cutoff)
            cutoff = cutoff.Values;
            cut = diff(cutoff.Data);
            fallIdx = find(cut>0)+1;
        else
            fallIdx = find(acqStarts<0)+1;
        end                    
        riseTimes = acqPulse.Time(riseIdx);                    
        fallTimes = acqPulse.Time(fallIdx);
        % keep/discard status
        trialStat = get(rtData, "buttonStat");
        trialStat = trialStat.Values;
        % trialStart = find(diff(trialStat.Data) == 1) + 1;
        trialKeepOrDrop_idx = find(diff(trialStat.Data) > 1) + 1;
        trialKeepOrDrop = trialStat.Data(trialKeepOrDrop_idx);
        % trialDiscard = find(diff(trialStat.Data) == 3) + 1;
        % sample rate calcs
        stimPreBuff_nSamp = 0.500 * 1/(acqPulse.Time(2) - acqPulse.Time(1));          
        numTrials = length(riseTimes);
        % loop through each trial and return metrics    
        % expmntData_ext.SLRT.trialNum = {};
        % expmntData_ext.SLRT.stimTrace_raw = {};
        % expmntData_ext.SLRT.stimTrace_lowess = {};
        % expmntData_ext.SLRT.responseDelay = {};
        % expmntData_ext.SLRT.responseThreshold = {};
        % expmntData_ext.SLRT.pawSide = {};
        % expmntData_ext.SLRT.QC = {};
        % expmntData_ext.SLRT.sessionType = {};
    
        for j=1:numTrials                
            trialTag = sprintf("t%d",j-1);
            % expmntData = validateTimeAxes(expmntData,trialTag);
            if regexp(rtSession, 'spontaneous', 'match', 'once') == "spontaneous"
                % write results          
                expmntData_ext.SLRT.sessionType = [expmntData_ext.SLRT.sessionType,'spontaneous'];
                expmntData_ext.SLRT.trialNum = [expmntData_ext.SLRT.trialNum; j-1];
                expmntData_ext.SLRT.stimTrace_raw = [expmntData_ext.SLRT.stimTrace_raw; nan];
                expmntData_ext.SLRT.stimTrace_lowess = [expmntData_ext.SLRT.stimTrace_lowess; nan];
                expmntData_ext.SLRT.responseDelay = [expmntData_ext.SLRT.responseDelay; nan];
                expmntData_ext.SLRT.responseThreshold = [expmntData_ext.SLRT.responseThreshold; nan];
                expmntData_ext.SLRT.pawSide = [expmntData_ext.SLRT.pawSide; nan];
                expmntData_ext.SLRT.QC = [expmntData_ext.SLRT.QC; 0];
            elseif trialKeepOrDrop(j) == 2
                % trialMask = [trialMask, j-1];
                % rise/fall indexing
                smoothMethod = 'filt';
                switch smoothMethod
                    case 'filt'
                        t_rise = riseTimes(j);
                    case 'lowess'
                        t_rise = riseTimes(j)-0.250;
                end            
                idx_rise = find(acqPulse.Time==t_rise);
                t_fall = fallTimes(j);
                idx_fall = find(acqPulse.Time==t_fall);
                % isolate stim waveform
                stimFiltTrial = stim_filt.Data(idx_rise-stimPreBuff_nSamp:idx_fall);                
                stimFiltTrial_time = stim_filt.Time(idx_rise-stimPreBuff_nSamp:idx_fall);
                stimRawTrial = stim_raw.Data(idx_rise-stimPreBuff_nSamp:idx_fall);            
                stimRawTrial_time = stim_raw.Data(idx_rise-stimPreBuff_nSamp:idx_fall);
                stimLowessTrial = lowess(stimRawTrial);
                idx_peakFilt = find(stimLowessTrial == max(stimLowessTrial));
                switch smoothMethod
                    case 'filt'
                        t_peak = stimFiltTrial_time(idx_peakFilt);            
                    case 'lowess'
                        t_peak = stimLowessTrial_time(idx_peakFilt);            
                end
    
                paw = regexp(rtSession, '([LR])-hind-paw', 'match', 'once');
                paw = string(paw);
                switch paw
                    case 'L-hind-paw'
                        pawSide = 'L';
                    case 'R-hind-paw'
                        pawSide = 'R';
                    otherwise
                        pawSide = nan;
                end           
                % write results     
                expmntData_ext.SLRT.sessionType = [expmntData_ext.SLRT.sessionType,'vonFrey'];
                expmntData_ext.SLRT.trialNum = [expmntData_ext.SLRT.trialNum; j-1];
                expmntData_ext.SLRT.stimTrace_raw = [expmntData_ext.SLRT.stimTrace_raw; stimRawTrial];
                expmntData_ext.SLRT.stimTrace_lowess = [expmntData_ext.SLRT.stimTrace_lowess; stimLowessTrial];
                expmntData_ext.SLRT.responseDelay = [expmntData_ext.SLRT.responseDelay; stimLowessTrial(idx_peakFilt)];            
                expmntData_ext.SLRT.responseThreshold = [expmntData_ext.SLRT.responseThreshold; t_peak - t_rise];
                expmntData_ext.SLRT.pawSide = [expmntData_ext.SLRT.pawSide; pawSide];
                expmntData_ext.SLRT.QC = [expmntData_ext.SLRT.QC; 0];          
            end                        
        end        
        expmntData_ext.LFP = [expmntData_ext.LFP; extractEXT_LFP(params, session, LFP, Q)];
    end
    expmntData_ext.SLRT = struct2table(expmntData_ext.SLRT);       
end
