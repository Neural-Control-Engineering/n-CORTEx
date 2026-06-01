function routerEntryChanged(nexon,entryPanel,entryfield)
    % update parameters and relevant scope dataframes, etc
    if strcmp(entryfield,"subject")
        entryfield = "subj";
    end
    value = entryPanel.Panel.(entryfield).uiField.Value;
    entryPanel.entryParams.(entryfield) = value;
    params = nexon.console.BASE.params;    
    % refind dropdown items    
    entryParams = nexon.console.BASE.router.entryParams;
    if isfield(entryParams,"subject")
        subjSessionLabels = nexon.console.BASE.DTS.sessionLabel(contains(nexon.console.BASE.DTS.sessionLabel,entryParams.subject));    
    elseif isfield(entryParams,"subj")
        subjSessionLabels = nexon.console.BASE.DTS.sessionLabel(contains(nexon.console.BASE.DTS.sessionLabel,entryParams.subj));    
    end
    parseSessionLabelUnique(subjSessionLabels,"date");
    subjXdateSessionLabels = subjSessionLabels(contains(subjSessionLabels,entryParams.date));    
    subjXdateXphaseLabels = subjXdateSessionLabels(contains(subjXdateSessionLabels,entryParams.phase));    
    nexon.console.BASE.router.Panel.date.uiField.Items=parseSessionLabelUnique(subjSessionLabels,"date");
    nexon.console.BASE.router.Panel.phase.uiField.Items=parseSessionLabelUnique(subjXdateSessionLabels,"phase");
    subjXdateXphaseTrialList = nexon.console.BASE.DTS.trialNumber(strcmp(nexon.console.BASE.DTS.sessionLabel,subjXdateXphaseLabels(1)));    
    nexon.console.BASE.router.Panel.trial.uiField.Items=string(num2str(subjXdateXphaseTrialList))';      
    % initialize trial selection
    if ~strcmp(entryfield,"trial")
        nexon.console.BASE.router.entryParams.trial = num2str(subjXdateXphaseTrialList(1));
    end

    if strcmp(entryfield,"subject") 
        nexon.console.BASE.router.UserData.subjectDir =  fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);
        nexon.console.BASE.router.UserData.subjectDir_cloud =  fullfile(params.paths.nCORTEx_cloud,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);
        try
            nexon.console.NPXLS.shanks.shank1.updateRegMap();
        catch e
            disp(getReport(e));
        end
    elseif strcmp(entryfield,"subj")
        nexon.console.BASE.router.UserData.subjectDir =  fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subj);
        nexon.console.BASE.router.UserData.subjectDir_cloud =  fullfile(params.paths.nCORTEx_cloud,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subj);
        try
            nexon.console.NPXLS.shanks.shank1.updateRegMap();
        catch e
            disp(getReport(e));
        end
    end

    % NPXLS UPDATE (apply new dataFrame for each shank --> existing timeCourse, spectrogram, etc)
    shankList = fieldnames(nexon.console.NPXLS.shanks);
    for i = 1:length(shankList)
        shank = shankList{i};
        scopeList = fieldnames(nexon.console.NPXLS.shanks.(shank).scope);
        for j = 1:length(scopeList)
            scope = scopeList{j};            
            dfID = nexon.console.NPXLS.shanks.(shank).scope.(scope).dfID_source; % grab trial-wise corresponding dfID        
            try
                dataFrame = grabDataFrame(nexon, dfID,[]);
            catch e
                disp(getReport(e))
                dataFrame=[];
            end
            if isempty(dataFrame)
                try
                    nexon.console.NPXLS.shanks.(shank).scope.(scope).DF=dtsIO_readDF(nexon,dfID,[]);
                catch e
                    disp(getReport(e));
                end
            else
                nexon.console.NPXLS.shanks.(shank).scope.(scope).dataFrame = dataFrame;
                nexon.console.NPXLS.shanks.(shank).scope.(scope).DF.df = dataFrame;
            end
            
            try
                nexon.console.NPXLS.shanks.(shank).scope.(scope).updateScope(nexon);
            catch
                try
                    nexon.console.NPXLS.shanks.(shank).scope.(scope).updateScope();
                catch e
                    disp(getReport(e));

                end
            end
        end
    end
    
    % SLRT UPDATE (apply new dataFrame (set))
    try
        % dfID = nexon.console.SLRT.signals.dfIDs; % grab current dfID
        % nexon.console.SLRT.signals.dataFrame = compileDataFrames(nexon, dfID);
        nexon.console.SLRT.signals.updateScope(nexon,  []);
    catch e
        disp(getReport(e))
    end
    % BASE UPDATE
    nexon.console.BASE.UserData.prevRouter.entryParams=nexon.console.BASE.router.entryParams; % keep track of most recent entryParams
    % grabDataFrame(nexon,"lfp");
    % broadcase 'trialChanged' trigger
    %%  EVENT MARKER TRIGGER
    % nexon.console.BASE.controlPanel.trig_trialChanged=~(nexon.console.BASE.controlPanel.trig_trialChanged);
end

% rw=6;
% t_pmtm = DTS_test(rw,:).t_pmtm{1};
% f_pmtm = DTS_test(rw,:).f_pmtm{1};
% psd = DTS_test(rw,:).PSD_pmtm{1};
% lfp = DTS_test(rw,:).lfp{1};
% lfpSpont = DTS_test(21,:).lfp{1};
% tPre = find(t_pmtm==-3);
% tPost = find(t_pmtm==0.25);
% psdPre = psd(:,:,tPre);
% psdPost = psd(:,:,tPost);
% 
% % WAVELETS
% % [wvs, f] = cwt(lfp(1,:),"morse",500,TimeBandwidth=20,VoicesPerOctave=8);
% [wvs, f] = cwt(lfp(1,:),"amor",500,VoicesPerOctave=8);
% figure; imagesc(t_pmtm,f,10*log10(abs(wvs)))
% title("trial")
% clim([-76.68167153828121,-35.48734493434856])
% figure; imagesc(t_pmtm,f,angle((wvs)))
% title("trial")
% % [wvs, f] = cwt(lfpSpont(1,3000:8500),"morse",500,TimeBandwidth=20,VoicesPerOctave=8);
% [wvs, f] = cwt(lfpSpont(1,3000:8500),"amor",500,VoicesPerOctave=8);
% figure; imagesc(t_pmtm,f,10*log10(abs(wvs)))
% title("spont")
% clim([-76.68167153828121,-35.48734493434856])
% figure; imagesc(t_pmtm,f,angle((wvs)))
% title("spont")

% fh = figure;
% t = tiledlayout(fh,1,2);
% nexttile(t);
% plot(f_pmtm,psdPre);
% nexttile(t);
% plot(f_pmtm,psdPost);

% tStart = find(t_pmtm==0);
% lfpPreWindow = lfp(1,tPre:tPre+500);
% lfpPostWindow = lfp(1,tStart:tStart+500);
% % [psdPre, fPre] = pmtm(lfpPreWindow,10,nfft/2,Fs,'Tapers','sine');    
% windowLen=500;
% [psdPre, fPre] = pwelch(lfpPreWindow, hanning(windowLen), floor(windowLen/2), nfft, Fs);
% % [psdPost, fPost] = pmtm(lfpPostWindow,10,nfft/2,Fs,'Tapers','sine');    
% [psdPost, fPost] = pwelch(lfpPostWindow, hanning(windowLen), floor(windowLen/2), nfft, Fs);
% fRange = [0,50];
% fCond_pre = (fPre>fRange(1))&(fPre<fRange(2));
% fCond_post = (fPost>fRange(1))&(fPost<fRange(2));
% 
% fh = figure;
% t = tiledlayout(fh,1,2);
% nexttile(t);
% plot(fPre(fCond_pre),log10(psdPre(fCond_pre)));
% % ylim([-11.2,-9.2]);
% ylim([-14,-7.5]);
% nexttile(t);
% plot(fPost(fCond_post),log10(psdPost(fCond_post)));
% % ylim([-11.2,-9.2]);
% ylim([-14,-7.5]);
