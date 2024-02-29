function lfpExt = loadEXT_LFP(params, session)
    % disp('loading LFP for %s',session);
    lfpExt = [];
    if sessionExists(params, session, "NPXLS", "RAW")
        lfp = [];
    end
end