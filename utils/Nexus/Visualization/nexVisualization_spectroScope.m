function nexVisualization_spectroScope(nexObj, args)
    
    % CFG HEADER    
    fRange_start = args.fRange_start; % default = 1
    fRange_end = args.fRange_end; % default = 50
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5
    zLim_low = args.zLim_low; % default = -13
    zLim_high = args.zLim_high; % default = -7

    % draw regMap colored specParams
    DF_specParam = nexObj.DF_postOp;
    
end