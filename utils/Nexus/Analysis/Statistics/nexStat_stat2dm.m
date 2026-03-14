function DM = nexStat_stat2dm(mdlObj, dmArgs)
    
    % CFG HEADER
    format = dmArgs.format; % default = 0

    switch format
        case 0 % batched
            DM = nexOp_stackSamples(STAT, 'batch');
        case 1 % stacked
            DM = nexOp_stackSamples(STAT, 'stack');
    end

end