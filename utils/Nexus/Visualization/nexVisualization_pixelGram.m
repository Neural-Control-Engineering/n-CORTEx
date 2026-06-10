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
    % reshape into neuropixels tensor-like
    is_rgb = (ndims(df_slice) == 3) || (size(df_slice,2) == 3 && ndims(df_slice) == 2);
    if is_rgb
        % truecolour path: squeeze singleton t dim, skip log and CLim
        df_slice = squeeze(df_slice);          % (n_chans x 3)
        df_NT = mat2NT(df_slice);              % (H x W x 3)
    else
        % greyscale path: log scale as before
        df_slice = ((20*log10(abs(df_slice))));
        df_NT = mat2NT(df_slice);              % (H x W)
    end
    % Update plot
    nexObj.Figure.panel0.tiles.graphics.canvas.CData = df_NT; % use custom function here to shape like probe
    % apply cLims (greyscale only; ignored when CData is truecolour)
    if ~is_rgb
        nexObj.Figure.panel0.tiles.graphics.canvas.Parent.CLim=[cLim_low, cLim_high];
    end
    % nexObj.Figure.panel0.tiles.ax.CLim=[cLim_low, cLim_high];
    % clim(nexObj.Figure.panel0.tiles.ax,[cLim_low, cLim_high]);

end