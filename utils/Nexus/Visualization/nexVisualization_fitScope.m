function nexVisualization_fitScope(nexObj, args)

    % CFG HEADER
    fRange_start = 1;
    fRange_end = 250;

    % DRAW DF (fit, and data) - reassign datafields of axis
    f = nexObj.DF.ax.f;    
    % ptr_chans = nexObj.fitCfg.fitPtr.chans;
    % ptr_t = nexObj.fitCfg.fitPtr.t;
    ptr_chans = nexObj.DF.ptr.chans;
    ptr_t = nexObj.DF.ptr.t;    
    % df sizes
    n_t  = size(nexObj.DF.ax.t, 2);      % number of time points
    n_chans = size(nexObj.DF.ax.chans, 2);  % number of channels    
    % safe circular indexing for time
    ptr_t_pre  = mod(ptr_t - 2, n_t) + 1;  % -1 in 1-based => subtract 2 before mod
    ptr_t_post = mod(ptr_t,     n_t) + 1;  % +1 in 1-based => subtract 0 before mod    
    % safe circular indexing for channels
    ptr_chans_pre  = mod(ptr_chans - 2, n_chans) + 1;
    ptr_chans_post = mod(ptr_chans,     n_chans) + 1;
    % f-range
    fCond = (f>fRange_start & f<fRange_end); % select frequencies   
    % POST OPERATIVE UPDATE
    nexObj.DF_postOp.df = nexObj.DF.df(ptr_chans,fCond,ptr_t); % df slice update
    nexObj.DF_postOp.ax.f=f(fCond);    
    % RE-VISUALIZATION
    % Corner frequencies
    try
        f_corner1 = log10(nexObj.DF_postOp.cf(1));
    catch e
        f_corner1 = 0;
    end
    try
        f_corner2 = log10(nexObj.DF_postOp.cf(2));
    catch e
        f_corner2 = 0;
    end
    % value updates
    nexObj.Figure.panel1.tiles.graphics.canvas_fit.YData = nexObj.DF_postOp.df_fit(fCond);
    nexObj.Figure.panel1.tiles.graphics.canvas_sig.YData = nexObj.DF.df(ptr_chans,fCond,ptr_t);
    nexObj.Figure.panel1.tiles.graphics.canvas_context1.YData =  nexObj.DF.df(ptr_chans,fCond,ptr_t_pre); % look behind (time)
    nexObj.Figure.panel1.tiles.graphics.canvas_context2.YData = nexObj.DF.df(ptr_chans,fCond,ptr_t_post);  % look ahead (time)
    nexObj.Figure.panel1.tiles.graphics.canvas_context3.YData = nexObj.DF.df(ptr_chans_pre,fCond,ptr_t); % look behind (space)
    nexObj.Figure.panel1.tiles.graphics.canvas_context4.YData = nexObj.DF.df(ptr_chans_post,fCond,ptr_t); % look ahead (space)
    nexObj.Figure.panel1.tiles.graphics.canvas_cornerFreq1.Value = f_corner1;
    nexObj.Figure.panel1.tiles.graphics.canvas_cornerFreq2.Value = f_corner2;    
    % nexObj.Figure.panel1.tiles.graphics.canvas_fit.Parent.YLim=[-170,-90];
end