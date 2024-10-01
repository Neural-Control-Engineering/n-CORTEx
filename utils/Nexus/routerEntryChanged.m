function routerEntryChanged(nexon,entryPanel,entryfield)
    % update parameters and relevant scope dataframes, etc
    value = entryPanel.Panel.(entryfield).uiField.Value;
    entryPanel.entryParams.(entryfield) = value;
    params = nexon.console.BASE.params;

    % refind dropdown items    
    entryParams = nexon.console.BASE.router.entryParams;
    subjSessionLabels = nexon.console.BASE.DTS.sessionLabel(contains(nexon.console.BASE.DTS.sessionLabel,entryParams.subject));    
    parseSessionLabelUnique(subjSessionLabels,"date");
    subjXdateSessionLabels = subjSessionLabels(contains(subjSessionLabels,entryParams.date));    
    subjXdateXphaseLabels = subjXdateSessionLabels(contains(subjXdateSessionLabels,entryParams.phase));    
    nexon.console.BASE.router.Panel.date.uiField.Items=parseSessionLabelUnique(subjSessionLabels,"date");
    nexon.console.BASE.router.Panel.phase.uiField.Items=parseSessionLabelUnique(subjXdateSessionLabels,"phase");
    subjXdateXphaseTrialList = nexon.console.BASE.DTS.trialNumber(strcmp(nexon.console.BASE.DTS.sessionLabel,subjXdateXphaseLabels(1)));    
    nexon.console.BASE.router.Panel.trial.uiField.Items=string(num2str(subjXdateXphaseTrialList))';      

    if strcmp(entryfield,"subject")
        nexon.console.BASE.router.UserData.subjectDir =  fullfile(params.paths.nCORTEx_local,"Project_Neuromodulation-for-Pain/Experiments/",params.extractCfg.experiment,"Subjects",nexon.console.BASE.router.entryParams.subject);
    end
    % NPXLS UPDATE (apply new dataFrame for each shank --> existing timeCourse, spectrogram, etc)
    shankList = fieldnames(nexon.console.NPXLS.shanks);
    for i = 1:length(shankList)
        shank = shankList{i};
        scopeList = fieldnames(nexon.console.NPXLS.shanks.(shank).scope);
        for j = 1:length(scopeList)
            scope = scopeList{j};
            dfID = nexon.console.NPXLS.shanks.(shank).scope.(scope).dfID; % grab trial-wise corresponding dfID
            dataFrame = grabDataFrame(nexon, dfID);
            nexon.console.NPXLS.shanks.(shank).scope.(scope).dataFrame = dataFrame;
            nexon.console.NPXLS.shanks.(shank).scope.(scope).updateScope(nexon, nexon.console.NPXLS.shanks.(shank));
        end
    end
    % grabDataFrame(nexon,"lfp");
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
