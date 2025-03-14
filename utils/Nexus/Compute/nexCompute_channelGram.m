function DF_postComp = nexCompute_channelGram(nexObj, args)    

    % CFG HEADER
    windowLen = args.windowLen; % default = 600
    stride = args.stride; % default = 50
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384    
    Fs = args.Fs; % default = 500

    DF = nexObj.DF;
    chanSel = [chanRange_start: chanRange_end];
    dfChanSel = DF.df(chanSel,:);
    % pad Df
    dfPad = nex_padDfZeros(dfChanSel,windowLen);
    % perform stft-like computation on df slices using opFcn, concatenate and return
    df_comp = [];
    t = []; 
    % for each time step; WINDOWING METHOD
    args_in = args;
    for i=1:stride:(size(dfPad,2)-windowLen)
        df_slice = dfPad(:,i:i+windowLen);        
        args_in.frameNum=i;
        opFcn_out = nexObj.opCfg.opFcn(df_slice, args_in);
        df_comp = cat(3, df_comp, opFcn_out.df);
        f = opFcn_out.ax.f;
        t = [t, i/Fs-nexObj.preBufferLen];
        % visualize on nexObj during computation here (if desired)
        nexVisualization_channelGram(nexObj.nexon, nexObj, nexObj.visCfg.entryParams);
        % drawnow
    end    

    DF_postComp.df = df_comp;
    DF_postComp.ax.f = f;
    DF_postComp.ax.t = t;
    DF_postComp.ax.chans = chanSel;
    DF_postComp.args = args;
end