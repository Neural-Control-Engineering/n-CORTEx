function expmntData_ext = extractJOLT(params, sessionsToExtract, Q)         
    sessions = sessionsToExtract.sessions;
    for i = 1:length(sessions)
        session = sessions{i};
        % function to return npxls acquisition times 
        % relative to user action (e.g. Button presses)      
        expmntData = [];
        expmntData_ext.SLRT = [];
        expmntData_ext.SLRT.trialNum = {};
        expmntData_ext.SLRT.stimTrace_raw = {};
        expmntData_ext.SLRT.stimTrace_lowess_span10 = {};
        expmntData_ext.SLRT.stimTrace_lowess_span2 = {};
        expmntData_ext.SLRT.responseDelay = {};
        expmntData_ext.SLRT.responseThreshold = {};
        expmntData_ext.SLRT.pawSide = {};
        expmntData_ext.SLRT.QC = {};
        expmntData_ext.SLRT.sessionType = {};
        expmntData_ext.SLRT.sessionLabel = {};
        expmntData_ext.LFP = [];
        
        % LOAD DATA OF INTEREST
        SLRT = loadEXT_SLRT(params, session);
        LFP = loadEXT_LFP(params, session);
    
        %% PROCESS SLRT LOG
        rtData = SLRT.data;
        rtSession = SLRT.meta.sessionLabel;
        % load stim trace                           
        % stim_filt = get(rtData,"stim_filt");
        % stim_filt = stim_filt.Values;
        stim_raw = get(rtData,"stim_raw");
        stim_raw = stim_raw.Values;    
        % acquisition timing
        acqPulse = get(rtData,"npxlsAcq_out");
        acqPulseType = class(acqPulse);
        if strcmp(acqPulseType,'Simulink.SimulationData.Dataset')
            acqPulse = acqPulse{1}.Values;
        else
            acqPulse = acqPulse.Values;
        end
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
        trialMask = [];
    
        for j=1:numTrials                
            trialTag = sprintf("t%d",j-1);
            % expmntData = validateTimeAxes(expmntData,trialTag);
            if regexp(rtSession, 'spontaneous', 'match', 'once') == "spontaneous"
                % write results          
                expmntData_ext.SLRT.sessionType = [expmntData_ext.SLRT.sessionType; 'spontaneous'];
                expmntData_ext.SLRT.trialNum = [expmntData_ext.SLRT.trialNum; j-1];
                expmntData_ext.SLRT.stimTrace_raw = [expmntData_ext.SLRT.stimTrace_raw; nan];
                expmntData_ext.SLRT.stimTrace_lowess_span10 = [expmntData_ext.SLRT.stimTrace_lowess_span10; stimLowessTrial_span10];
                expmntData_ext.SLRT.stimTrace_lowess_span2 = [expmntData_ext.SLRT.stimTrace_lowess_span2; stimLowessTrial_span2];
                expmntData_ext.SLRT.responseDelay = [expmntData_ext.SLRT.responseDelay; nan];
                expmntData_ext.SLRT.responseThreshold = [expmntData_ext.SLRT.responseThreshold; nan];
                expmntData_ext.SLRT.pawSide = [expmntData_ext.SLRT.pawSide; nan];
                expmntData_ext.SLRT.QC = [expmntData_ext.SLRT.QC; 0];
                expmntData_ext.SLRT.sessionLabel = [expmntData_ext.SLRT.sessionLabel; session];
            elseif trialKeepOrDrop(j) == 2
                trialMask = [trialMask, j-1];
                % rise/fall indexing
                % smoothMethod = 'filt';
                % switch smoothMethod
                %     case 'filt'
                %         t_rise = riseTimes(j);
                %     case 'lowess'
                %         t_rise = riseTimes(j)-0.250;
                % end            
                t_rise = riseTimes(j);
                idx_rise = find(acqPulse.Time==t_rise);
                t_fall = fallTimes(j);
                idx_fall = find(acqPulse.Time==t_fall);
                % isolate stim waveform
                % stimFiltTrial = stim_filt.Data(idx_rise-stimPreBuff_nSamp:idx_fall);                
                % stimFiltTrial_time = stim_filt.Time(idx_rise-stimPreBuff_nSamp:idx_fall);                
                stimRawTrial = stim_raw.Data(idx_rise-stimPreBuff_nSamp*2:idx_fall+stimPreBuff_nSamp);            
                stimRawTrial_time = stim_raw.Time(idx_rise-stimPreBuff_nSamp*2:idx_fall+stimPreBuff_nSamp);
                t_rise_trial = stim_raw.Time(idx_rise);
                idx_rise_trial = find(stimRawTrial_time==t_rise_trial);
                stimLowessTrial_span10 = lowess(stimRawTrial,0.12);                
                stimLowessTrial_span2 = lowess(stimRawTrial,0.02);         
                % stimLowessTrial_span10=stimRawTrial;                
                % stimLowessTrial_span2 =stimRawTrial;         
                figure; plot(stimLowessTrial_span10);                 
                hold on
                plot(stimLowessTrial_span2);                 
                idx_peakFilt = find(stimLowessTrial_span10 == max(stimLowessTrial_span10));
                % idx_peakFilt = 10;
                t_peak = stimRawTrial_time(idx_peakFilt);
                idx_peak_trial = find(stimRawTrial_time==t_peak)
                xline(idx_rise_trial)
                xline(idx_peak_trial)
                title(session)
                hold off
                
                % switch smoothMethod
                %     case 'filt'
                %         t_peak = stimFiltTrial_time(idx_peakFilt);            
                %     case 'lowess'
                %         t_peak = stimLowessTrial_time(idx_peakFilt);            
                % end
    
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
                expmntData_ext.SLRT.sessionType = [expmntData_ext.SLRT.sessionType; 'vonFrey'];
                expmntData_ext.SLRT.trialNum = [expmntData_ext.SLRT.trialNum; j-1];
                expmntData_ext.SLRT.stimTrace_raw = [expmntData_ext.SLRT.stimTrace_raw; stimRawTrial];
                expmntData_ext.SLRT.stimTrace_lowess_span10 = [expmntData_ext.SLRT.stimTrace_lowess_span10; stimLowessTrial_span10];
                expmntData_ext.SLRT.stimTrace_lowess_span2 = [expmntData_ext.SLRT.stimTrace_lowess_span2; stimLowessTrial_span2];
                expmntData_ext.SLRT.responseThreshold = [expmntData_ext.SLRT.responseThreshold; stimLowessTrial_span10(idx_peakFilt)];            
                expmntData_ext.SLRT.responseDelay = [expmntData_ext.SLRT.responseDelay; t_peak - t_rise];
                expmntData_ext.SLRT.pawSide = [expmntData_ext.SLRT.pawSide; pawSide];
                expmntData_ext.SLRT.QC = [expmntData_ext.SLRT.QC; 0];          
                expmntData_ext.SLRT.sessionLabel = [expmntData_ext.SLRT.sessionLabel; session];
            end                                    
        end        
        sessionFileLabel = sprintf("%s.mat",session);
        extractionLog = params.extrctItms.EXT.extractionLog;
        expmntData_ext.SLRT = struct2table(expmntData_ext.SLRT);     
        % export SLRT and log
        SLRT = expmntData_ext.SLRT;
        save(fullfile(params.paths.Data.EXT.SLRT.cloud,sessionFileLabel),'SLRT');
        extractionLog = updateExtractionLog(extractionLog,session,"Extracted_SLRT",1,0);
        % export LFP and log        
        LFP = extractEXT_LFP(params, session, LFP, Q);
        if ~exist(fullfile(params.paths.stem,"Temp"),"dir"); mkdir(fullfile(params.paths.stem,"Temp")); end
        save(fullfile(params.paths.stem,"Temp",sessionFileLabel),'LFP','-mat');
        movefile(fullfile(params.paths.stem,"Temp",sessionFileLabel),(fullfile(params.paths.Data.EXT.LFP.cloud,sessionFileLabel)));
        % save(fullfile(params.paths.Data.EXT.LFP.cloud,sessionFileLabel),'LFP');
        extractionLog = updateExtractionLog(extractionLog,session,"Extracted_LFP",1,0);
        % save progress
        writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));
        % writetable(extractionLog, fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv","EXT")));
        % expmntData_ext.LFP = [expmntData_ext.LFP; extractEXT_LFP(params, session, LFP, Q)];
        params.extrctItms.EXT.extractionLog = extractionLog;
        

    end
    % expmntData_ext.SLRT = struct2table(expmntData_ext.SLRT);     
    % exportEXT_LFP(params,expmntData_ext.LFP);
    % exportEXT_SLRT(params,expmntData_ext.SLRT);
end
