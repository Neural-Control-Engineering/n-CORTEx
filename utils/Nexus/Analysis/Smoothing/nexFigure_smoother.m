function nexFigure_smoother(nexObj)
    nexObj.Figure.fh = uifigure("Position",[100,1260,900,720],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel0.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,700,680],"BackgroundColor",[0,0,0]);
    % cfg panel
    panel1.ph = uipanel(nexObj.Figure.fh,"Position",[710,5,185,710],"BackgroundColor",[0,0,0],"Scrollable","on");
    cfgEntryChangedFcn = str2func("cfgEntryChanged_v2");
    % entryFormArgs = nexObj.fitCfg.entryParams;
    % entryFormArgs.entryHeightScaler=30;
    % entryFormArgs.cfgFieldName = "fitCfg";
    opArgs = nexObj.cfg.opCfg.entryParams;
    uiFieldArgs.entryHeightScaler=30;
    nexObj.Figure.panel1 = nexObj_cfgPanel_v2(nexObj, nexObj.cfg.opCfg, panel1, opArgs, cfgEntryChangedFcn, uiFieldArgs);
    %% graphics
    f = nexObj.DF.ax.f;    
    f=log10(f);
    numTicks = 30;
    f_ticks = (logspace(log10(f(1)), log10(f(end)), numTicks));
    nexObj.Figure.panel0.tiles.t = tiledlayout(nexObj.Figure.panel0.ph,1,1);    
    nexObj.Figure.panel0.tiles.Axes.smth = nexttile(nexObj.Figure.panel0.tiles.t);
    ax_canvas = nexObj.Figure.panel0.tiles.Axes.smth;    
    hold(ax_canvas,"on");
    nexObj.Figure.panel0.tiles.graphics.canvas_psd = plot(ax_canvas, f, nexObj.DF.df);
    nexObj.Figure.panel0.tiles.graphics.canvas_smooth = plot(ax_canvas, f, nexObj.DF_postOp.df);
    colorAx_green(ax_canvas);
end