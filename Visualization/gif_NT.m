function gif_NT(NT, t, t_range, fileName, CT)    
    
    t_cond = t > t_range(1) & t < t_range(2);    

    % plot Gif over axis  

    NTaxs.t = t(t_cond);    
    NTaxs.chan = 1:96;
    NTaxs.sweepAx='t';

    NTData.dataStream = NT(:,:,t_cond);
    NTData.axs = NTaxs;
    NTData.plot='NT';
    NTData.label='sec';
    NTData.sweepDim = 3;
    NTData.colorMap = CT;

    gifCfg.filename='NT_6736_t7_3_11.gif';
    % gifCfg.filename=sprintf("NT_%s.gif");
    gifCfg.frameDelay = 0.01;
    gifOverAxis(gifCfg, {NTData});
end