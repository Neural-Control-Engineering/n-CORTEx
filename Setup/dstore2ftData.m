function ftData = dstore2ftData(params, lfp)
    % build fieldtrip toolbox data structure from raw datastore data
    % dataField input might be a multichannel time series data stream such
    % as lfp or action potential
    dataFieldSize = size(lfp);
    numTrials = 1; % keeping this =1 for now for testing
%     numChannels = dataFieldSize(1);
    numTimePoints = dataFieldSize(2);
    numChannels = 384;
    t = [1:1:dataFieldSize(2)];
    for i = 1:numTimePoints; t(i) = i/params.extractCfg.LFP.Fs_downSamp; end %% UPDATE TO REFLECT dataField (if not lfp)
    for rpt = 1:1
        ftData.trial{1,rpt} = lfp;
        ftData.time{1, rpt} = t;
        ftData.label{1} = 'chan';
        ftData.trialinfo(rpt,1) = rpt;
    end 
    
    switch params.sampleRange.target
        case 'baseline'
            ftData.sampleinfo = params.sampleRange.baseline * params.acquisition.Fs_lfp;
        case 'stim'
            ftData.sampleinfo = params.sampleRange.stim * params.acquisition.Fs_lfp;
        case 'all'
            ftData.sampleinfo = 1 : size(lfp,2)
        otherwise
            ftData.sampleinfo = [1 1750];
    end

    % ftData.fsample = params.acquisition.Fs_lfp;
    ftData.fsample = params.extractCfg.LFP.Fs_downSamp;
    % initialize data strucutre as raw for all channels
    labels = cell(numChannels,1);
    % labels{1} = 'raw';
    for i = 1:numChannels; labels{i} = sprintf('%d',i); end
    ftData.label = convertCharsToStrings(labels);
    
end