function nexVisualization_pixelGram(nexObj, args)
    
    % CFG HEADER
    cLim_low = args.cLim_low; % default = -90
    cLim_high = args.cLim_high; % default = -60
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384

    ptr = nexObj.DF_postOp.ptr;  
    axSel = string(nexObj.Figure.axSelDropDown.Value);
    % slice DF
    df = nexObj.DF_postOp.df;
    df_slice = sliceDF(df,ptr,axSel);
    % scale to log
    df_slice = ((20*log10(abs(df_slice))));
    % apply chan ranges
    % reshape into neuropixels tensor-like
    df_NT = mat2NT(df_slice);    
    % Update plot
    nexObj.Figure.panel0.tiles.graphics.canvas.CData = df_NT; % use custom function here to shape like probe
    % apply cLims
    nexObj.Figure.panel0.tiles.graphics.canvas.Parent.CLim=[cLim_low, cLim_high];
    % nexObj.Figure.panel0.tiles.ax.CLim=[cLim_low, cLim_high];
    % clim(nexObj.Figure.panel0.tiles.ax,[cLim_low, cLim_high]);

end