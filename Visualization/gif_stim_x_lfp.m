function gif_stim_x_lfp(stim, stim_prebuff, lfp, lfp_prebuff, Fs, t_range)    
    t_stim = ([1:size(stim,2)] - stim_prebuff) ./ Fs;
    % t_lfp = ([1:size(lfp,2)] - lfp_prebuff) ./ Fs;    
    t_stim_cond = t_stim > t_range(1) & t_stim < t_range(2);
    % t_lfp_cond = t_lfp > t_range(1) & t_lfp < t_range(2);
    stim_piece = stim(t_stim_cond);
    % lfp_piece = lfp(:,t_lfp_cond);
    [lfp_PSD_micro, f_micro, t_micro] = multiSpectrogram(lfp, Fs, 80, 79, 1);
    lfp_PSD = 10*log10(abs(lfp_PSD_micro));
    lfp_PSD = permute(lfp_PSD(:,:,1:384),[3,1,2]);
    psd_prebuff = lfp_prebuff - 80/2;
    t_psd = ([1:size(lfp_PSD_micro,2)] - psd_prebuff) ./ Fs;
    t_psd_cond = t_psd > t_range(1) & t_psd < t_range(2);
    lfp_PSD_piece = lfp_PSD(:,:,(t_psd_cond));

    % plot Gif over axis    
    stimAxs.t = t_stim(t_stim_cond);
    stimAxs.sweepAx = 't'; 
    stimAxs.traceAx = 't';    
    stimData.dataStream = stim_piece';
    stimData.axs = stimAxs; 
    stimData.plot = 'trace';
    stimData.label = "sec";
    stimData.bufferDim=1;
    stimData.sweepDim = 1;    
    
    evkSpecAxs.t = t_psd(t_psd_cond);
    evkSpecAxs.f = f_micro;
    evkSpecAxs.chan = [1:1:384];
    evkSpecAxs.sweepAx='t';
    evkData.dataStream = lfp_PSD_piece;
    evkData.axs = evkSpecAxs;
    evkData.plot='channelgram';
    evkData.label='sec';
    evkData.sweepDim = 3;

    gifCfg.filename='EvokedSingle_6735_t34_3_13.gif';
    gifCfg.frameDelay = 0.01;
    gifOverAxis(gifCfg, {stimData; evkData});


end