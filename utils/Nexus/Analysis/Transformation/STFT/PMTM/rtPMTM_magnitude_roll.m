function DF_out = rtPMTM_magnitude_roll(DF, args)
    % CFG HEADER
    windowLen = args.windowLen; % default = 600
    stride = args.stride; % default = 50
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384    
    Fs = args.Fs; % default = 500
    preBuffLen = args.preBuffLen;

    % DF = nexObj.DF;
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
        % opFcn_out = nexObj.opCfg.opFcn(df_slice, args_in);
        df_out = rtPMTM_magnitude(df_slice, args_in);
        df_comp = cat(3, df_comp, df_out.df);
        f = df_out.ax.f;
        t = [t, i/Fs-preBuffLen];        
        % drawnow
    end    

    DF_out.df = df_comp;
    DF_out.ax.f = f;
    DF_out.ax.t = t;
    DF_out.ax.chans = chanSel;
    DF_out.args = args;
end