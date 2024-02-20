function extraction(params)
    % TIER 1 : RAW
    % run basic extraction for raw data from each modality acquired during
    % experimentation
    if params.extractCfg.extractRAW
        extractRAW(params);
    end

    % TIER 2 : EXTRACTED
    % experiment specific, trial-wise pre-processing of data modalities
    if params.extractCfg.extractEXT
        extractEXT(params);
    end

    % TIER 3 : DATASTORE
    % user-generated datastore prepped for analysis
    if params.extractCfg.extractDTS
        extractDTS(params);
    end

end