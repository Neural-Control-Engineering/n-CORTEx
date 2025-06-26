function DF_postComp = nexCompute_spectroScope(nexObj, args)

    % CFG HEADER 
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384    
    peakWidth_min = args.peakWidth_min; % default = 2
    peakWidth_max = args.peakWidth_max; % default = 8    
    numPeaks_max = args.numPeaks_max; % default = 8
    peakHeight_min = args.peakHeight_min; % default = 0.2    
    peakThreshold = args.peakThreshold; % default = 2

    DF = nexObj.DF;         
    DF_postComp = nexObj.opCfg.opFcn(nexObj.DF, args);           
    DF_postComp.args = args;
end