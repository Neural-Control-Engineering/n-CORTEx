function nexVisualization_fitScope(nexObj, args) %#ok<INUSD>
% Redraw nexObj_fitScope's canvas in place — full fit curve, aperiodic-
% only overlay (peaks nulled — disambiguates the two visually), raw
% signal + 4 context traces, and up to 3 corner-frequency lines, all read
% from the CURRENT collector.Pointer chan/t position and fitCfg.entryParams
% (DF_postOp.df_fit/.df_fit_ap are expected to already be recomputed by
% the caller — see nexObj_fitScope.redraw).

    % CFG HEADER
    fRange_start = 1;
    fRange_end   = 250;

    [ptr_chans, ptr_t] = nexObj.currentPtr();
    f = nexObj.DF_postOp.ax.f;
    n_t     = numel(nexObj.DF_postOp.ax.t);
    n_chans = numel(nexObj.DF_postOp.ax.chans);
    ptr_t_pre      = mod(ptr_t - 2, n_t) + 1;
    ptr_t_post     = mod(ptr_t,     n_t) + 1;
    ptr_chans_pre  = mod(ptr_chans - 2, n_chans) + 1;
    ptr_chans_post = mod(ptr_chans,     n_chans) + 1;

    fCond = (f > fRange_start & f < fRange_end);

    nexObj.Figure.panel1.tiles.graphics.canvas_fit.YData      = nexObj.DF_postOp.df_fit(fCond);
    nexObj.Figure.panel1.tiles.graphics.canvas_fit_ap.YData   = nexObj.DF_postOp.df_fit_ap(fCond);
    nexObj.Figure.panel1.tiles.graphics.canvas_sig.YData      = squeeze(nexObj.DF_postOp.df(ptr_chans, fCond, ptr_t));
    nexObj.Figure.panel1.tiles.graphics.canvas_context1.YData = squeeze(nexObj.DF_postOp.df(ptr_chans, fCond, ptr_t_pre));
    nexObj.Figure.panel1.tiles.graphics.canvas_context2.YData = squeeze(nexObj.DF_postOp.df(ptr_chans, fCond, ptr_t_post));
    nexObj.Figure.panel1.tiles.graphics.canvas_context3.YData = squeeze(nexObj.DF_postOp.df(ptr_chans_pre, fCond, ptr_t));
    nexObj.Figure.panel1.tiles.graphics.canvas_context4.YData = squeeze(nexObj.DF_postOp.df(ptr_chans_post, fCond, ptr_t));

    for k = 1:3
        fld  = sprintf("FC%d", k);
        fcID = sprintf("canvas_cornerFreq%d", k);
        try
            fcVal = nexObj.fitCfg.entryParams.(fld);
            nexObj.Figure.panel1.tiles.graphics.(fcID).Value = log10(max(fcVal, eps));
        catch
        end
    end
end
