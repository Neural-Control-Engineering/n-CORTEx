function nexFigure_fitScope(nexObj)

    % CFG HEADER
    fRange_start = 1;
    fRange_end = 250;

    % use model function and model parameters
    nexObj.Figure.fh = uifigure("Position",[100,1260,900,720],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,680],"BackgroundColor",[0,0,0]);
    % cfg panel
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[710,5,185,710],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel3.ph = uipanel(nexObj.Figure.panel2.ph,"Position",[5,80,160,630],"BackgroundColor",[0,0,0],"Scrollable","on");
    nexObj.Figure.panel4.ph = uipanel(nexObj.Figure.panel2.ph,"Position",[5,5,160,75],"BackgroundColor",[0,0,0],"Scrollable","on");
    % nexObj.Figure.panel5.ph = uipanel(nexObj.Figure.panel2.ph,"Position",[])
    cfgEntryChangedFcn = str2func("cfgEntryChanged");
    % entryFormArgs = nexObj.fitCfg.entryParams;
    entryFormArgs.entryHeightScaler=30;
    entryFormArgs.cfgFieldName = "fitCfg";
    nexObj.Figure.panel2 = nexObj_cfgPanel_spinner(nexObj.nexon,nexObj,nexObj.Figure.panel3,nexObj.fitCfg.entryParams,cfgEntryChangedFcn,entryFormArgs);
    % filter KNE parameters as decibel range

    % user-interface for accepting/discardings
    nexObj.Figure.saveButton = uibutton(nexObj.Figure.panel4.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberGreen,"ButtonPushedFcn",@(src,event) nexObj.saveFit(src, event),"Position",[5,5,140,25],"Text",""); 
    nexObj.Figure.connectDB = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(src,event)nexObj.connectDB(src,event),"Position",[5,685,25,25],"Text","");
    nexObj.Figure.nullPeaksButton = uicontrol(nexObj.Figure.panel4.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberGrey,"ButtonDownFcn",@(src,event) nexObj.nullifyPeaks(src, event),"Callback",@(src,event) nexObj.nullifyPeaks(src, event),"Position",[75,35,25,25],"String","");
    % nexObj.Figure.discardButton = uibutton(nexObj.Figure.panel4.ph,"BackgroundColor",nexObj.nexon.settings.Colors.cyberRed,"ButtonPushedFcn",@(~,~)nexObj.discardFit(),"Position",[80,5,70,65],"Text","");     
    % AXES
    %% DEFAULT SPECPARAM - time and space alts (may generalize later)
    nexObj.Figure.ax1Spinner = uispinner("Parent",nexObj.Figure.panel4.ph,"Position",[5,35,55,25],"FontColor",[0.30,0.75,0.93],"BackgroundColor",[0,0,0],"Value",1,"ValueChangedFcn",@(src,event) nexObj.setAxisPointer(src, event, "t"));
    % nexObj.Figure.ax2Spinner = uispinner("Parent",nexObj.Figure.panel4.ph,"Position",[55,35,45,25],"Value",1,"ValueChangedFcn",@(~,~)nexObj.incrementAxisPointer(nexObj,2));
    nexObj.Figure.ax3Spinner = uispinner("Parent",nexObj.Figure.panel4.ph,"Position",[100,35,55,25],"FontColor",[0.93,0.69,0.13],"BackgroundColor",[0,0,0],"Value",1,"ValueChangedFcn",@(src,event) nexObj.setAxisPointer(src, event, "chans"));
    nexObj.Figure.panel1.tiles.t = tiledlayout(nexObj.Figure.panel1.ph,1,1);    
    nexObj.Figure.panel1.tiles.Axes.fitScp = nexttile(nexObj.Figure.panel1.tiles.t);
    ax_canvas = nexObj.Figure.panel1.tiles.Axes.fitScp;    
    hold(ax_canvas,"on");
    % plot initial DF slices
    f = nexObj.DF.ax.f;    
    % ptr_chans = nexObj.fitCfg.fitPtr.chans;
    % ptr_t     = nexObj.fitCfg.fitPtr.t;    
    ptr_chans = nexObj.DF.ptr.chans;
    ptr_t     = nexObj.DF.ptr.t;    
    % df sizes
    n_t  = size(nexObj.DF.ax.t, 2);      % number of time points
    n_chans = size(nexObj.DF.ax.chans, 2);  % number of channels    
    % safe circular indexing for time
    ptr_t_pre  = mod(ptr_t - 2, n_t) + 1;  % -1 in 1-based => subtract 2 before mod
    ptr_t_post = mod(ptr_t,     n_t) + 1;  % +1 in 1-based => subtract 0 before mod    
    % safe circular indexing for channels
    ptr_chans_pre  = mod(ptr_chans - 2, n_chans) + 1;
    ptr_chans_post = mod(ptr_chans,     n_chans) + 1;
    % plot in double log
    % f-Range
    fCond = (f>fRange_start & f<fRange_end); % select frequencies   
    % Generate logarithmically spaced tick positions
    f=log10(f(fCond));
    numTicks = 30;
    f_ticks = (logspace(log10(f(1)), log10(f(end)), numTicks));
    % f_ticks = (logspace((f(1)), (f(end)), numTicks));
    %% Corner frequencies
    try
        f_corner1 = log10(nexObj.DF_postOp.cf(1));
    catch
    end
    try
        f_corner2 = log10(nexObj.DF_postOp.cf(2));
    catch
    end
    
    %% Plot canvases
    nexObj.Figure.panel1.tiles.graphics.canvas_fit = plot(ax_canvas, f, nexObj.DF_postOp.df_fit(fCond),"Color",nexObj.nexon.settings.Colors.cyberRed);
    nexObj.Figure.panel1.tiles.graphics.canvas_fit.Parent.XTick = f_ticks;
    nexObj.Figure.panel1.tiles.graphics.canvas_fit.Parent.XTickLabel = 10.^(f_ticks);
    nexObj.Figure.panel1.tiles.graphics.canvas_sig = plot(ax_canvas, f, nexObj.DF.df(ptr_chans,fCond,ptr_t),"Color",nexObj.nexon.settings.Colors.cyberGreen,"LineWidth",1.5);
    nexObj.Figure.panel1.tiles.graphics.canvas_context1 = plot(ax_canvas, f, nexObj.DF.df(ptr_chans,fCond,ptr_t_pre),"Color",[0.2510    0.3569    0.4000]); % look behind (time)
    nexObj.Figure.panel1.tiles.graphics.canvas_context2 = plot(ax_canvas, f, nexObj.DF.df(ptr_chans,fCond,ptr_t_post),"Color",[0    0.2588    0.3608]);  % look ahead (time)
    nexObj.Figure.panel1.tiles.graphics.canvas_context3 = plot(ax_canvas, f, nexObj.DF.df(ptr_chans_pre,fCond,ptr_t),"Color",[0.4510    0.4157    0.3137]); % look behind (space)
    nexObj.Figure.panel1.tiles.graphics.canvas_context4 = plot(ax_canvas, f, nexObj.DF.df(ptr_chans_post,fCond,ptr_t),"Color",[0.3608    0.2706         0]); % look ahead (space)
    try
        nexObj.Figure.panel1.tiles.graphics.canvas_cornerFreq1 = xline(ax_canvas, f_corner1, "Color",nexObj.nexon.settings.Colors.cyberGreen);
    catch        
    end
    try
        nexObj.Figure.panel1.tiles.graphics.canvas_cornerFreq2 = xline(ax_canvas, f_corner2, "Color",nexObj.nexon.settings.Colors.cyberGreen);
    catch
    end
    colorAx_green(ax_canvas);


end