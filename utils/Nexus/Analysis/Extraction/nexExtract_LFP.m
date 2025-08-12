function DF_lfp = nexExtract_LFP(lfp)
    % LFP basic preprocessing
    % Anti-aliasing
    Fs = str2double(lfp.meta.imSampRate);
    d = designfilt('bandpassiir', ...
                'FilterOrder', 4, ...
                'HalfPowerFrequency1', 0.1, ...
                'HalfPowerFrequency2', 100, ...
                'DesignMethod', 'butter', ...
                'SampleRate', Fs);                                                       
    args_antiAlias.Fs = Fs;
    args_antiAlias.contextWin = 50;
    lfp_filt = antiAlias(lfp.dataArray, d, args_antiAlias );
    % downsampling
    downSampleRate=5;
    lfp_downSample = downsample(lfp_filt',downSampleRate)';   
    lfp.dataArray = lfp_downSample;
    lfp.meta.Fs=Fs/downSampleRate;
    lfp.meta.preBuffLen = 3.5;                             
    % PCA removal
    pcaRmArgs = extractMethodCfg(('nex_pcaNoiseRm'));
    % DF_lfp = nex_pcaNoiseRm(lfp.dataArray,pcaRmArgs);
    DF_lfp.df=nex_pcaNoiseRm(lfp.dataArray,pcaRmArgs);
end