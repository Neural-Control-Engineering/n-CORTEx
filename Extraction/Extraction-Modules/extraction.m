function extraction(params)    

    % TIER 1 : RAW
    % run basic extraction for raw data from each modality acquired during
    % experimentation    
    if strcmp(params.extrctItms.RAW.RAWSwitch.Value,'On')
        extractRAW(params);
    end
    

    % TIER 2 : EXTRACTED
    % experiment specific, trial-wise pre-processing of data modalities    
    if strcmp(params.extrctItms.EXT.EXTSwitch.Value,'On')
        extractEXT(params);
    end


    % TIER 3 : DATASTORE
    % user-generated datastore prepped for analysis    
    if strcmp(params.extrctItms.DTS.DTSSwitch.Value,'On')
        extractDTS(params);
    end
    

    % TIER 4 : FEATURE / VECTOR SET
    % feature array for classification and machine learning
    if strcmp(params.extrctItms.FTR.FTRSwitch.Value,'On')
        extractFTR(params);
    end

end