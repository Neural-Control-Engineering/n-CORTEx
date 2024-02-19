%% DEFINE 
TRIAL_DURATION = 5;
MAX_SESSION_DURATION = 35 * 60; % 35 minutes converted to seconds
LFP_FS = params.extractCfg.LFP.Fs;
LFP_DWNSMP = params.extractCfg.LFP.downSamp;    
NUMPROBE = params.extractCfg.npxls.numProbes;    

numTrialLfpSamps = (LFP_FS / LFP_DWNSMP) * TRIAL_DURATION;
maxLfpSamps = (LFP_FS / LFP_DWNSMP) * MAX_SESSION_DURATION;
sampStep = round(MAX_SESSION_DURATION / TRIAL_DURATION );
lfp_fs = LFP_FS / LFP_DWNSMP;
psdCbar = [-100, -20];
lfpCbar = [-7e-04, 7e-04];
segLen = 

%% Average Spontaneous
spontTrials = dataStore(dataStore.pawSide=="spontaneous",:);
spontSegs = cellfun(@(trial) segmentSeries(trial, segLen, dim), spontTrials, 'UniformOutput',false);
spontLFP = spontTrials.LFP_npxls0;
spontLFP = cellfun(@(x) x(1:384,1:5000), spontLFP, 'UniformOutput',false);
avgSpont = cat(3, spontLFP{:});
avgSpont = mean(avgSpont,3);
% VISUALIZE
windowSize = 80; overlap =75;
lfpMat = avgSpont;
[lfp_spectrogram, f, t] = multiSpectrogram(lfpMat, lfp_fs, windowSize, overlap, 1);
lfp_spectrogram = 10*log10(abs(lfp_spectrogram));
lfp_spectrogram = permute(lfp_spectrogram,[3, 1, 2]);
gifName = sprintf("%s_chanSpcgrmXtime.gif", trialLabel);
gifCfg.frameDelay=1/lfp_fs;
gifCfg.filename = "chanSpcgrmXtime.gif";
data.dataStream = {lfp_spectrogram}; 
data.axs.t = t;
data.axs.f = f';
data.axs.sweepAx = 't';
data.label = "(sec)";
data.plotMethod='channelgram';
data.caxis = psdCbar;
gifOverAxis(gifCfg, data, 3);

%% 
lfp_spectrogram = permute(lfp_spectrogram,[2, 3, 1]);
data.dataStream = {lfp_spectrogram}; 
data.axs.t = t;
data.axs.f = f';
data.axs.chan =  [1:1:size(avgSpont,1)];
data.axs.sweepAx = 'chan';
data.label = "(channel)";
data.plotMethod='spectrogram';
data.caxis = psdCbar;
gifOverAxis(gifCfg, data, 3);

%% Neuropixels Tensor
spontNT = mapChan2Npxl(params, avgSpont);
%% VISUALIZE
data.dataStream = {spontNT}; 
data.axs.t = timeAxis(avgSpont, lfp_fs, 2);
data.axs.f = f';
data.axs.chan =  [1:1:size(avgSpont,1)];
data.axs.sweepAx = 't';
data.label = "(sec)";
data.plotMethod='NT';
data.caxis = lfpCbar;
gifOverAxis(gifCfg, data, 3);

%% Average Vonfrey
evokedTrials = dataStore(dataStore.pawSide~="spontaneous",:);
evokedTrials = evokedTrials(96:end,:);
evokedLFP = evokedTrials.LFP_npxls0;
evokedLFP = cellfun(@(x) x(1:384, 1:3000), evokedLFP, 'UniformOutput', false);
% Concatenate the matrices along a new dimension (e.g., 3)
concatenatedMatrices = cat(3, evokedLFP{:});
% Calculate the mean along the third dimension
avgEvoked = mean(concatenatedMatrices, 3);
% VISUALIZE
windowSize = 100; overlap =90;
lfpMat = avgEvoked;
[lfp_spectrogram, f, t] = multiSpectrogram(lfpMat, lfp_fs, windowSize, overlap, 1);
lfp_spectrogram = 10*log10(abs(lfp_spectrogram));
lfp_spectrogram = permute(lfp_spectrogram,[3, 1, 2]);
gifName = sprintf("%s_chanSpcgrmXtime.gif", trialLabel);
gifCfg.frameDelay=1/lfp_fs;
gifCfg.filename = "chanSpcgrmXtime.gif";
data.dataStream = {lfp_spectrogram}; 
data.axs.t = t;
data.axs.f = f';
data.axs.sweepAx = 't';
data.label = "(sec)";
data.plotMethod='spectrogram';
data.caxis = psdCbar;
gifOverAxis(gifCfg, data, 3);

%% Neuropixels Tensor
evokedNT = mapChan2Npxl(params, avgEvoked);
%% VISUALIZE
data.dataStream = {evokedNT}; 
data.axs.t = timeAxis(avgEvoked, lfp_fs, 2);
data.axs.f = f';
data.axs.chan =  [1:1:size(avgEvoked,1)];
data.axs.sweepAx = 't';
data.label = "(sec)";
data.plotMethod='NT';
data.caxis = lfpCbar;
gifCfg.frameDelay=0.001;
gifOverAxis(gifCfg, data, 3);
