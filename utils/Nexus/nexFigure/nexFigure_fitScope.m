function nexFigure_fitScope(nexObj)
% Figure for the modernized nexObj_fitScope.
%   panel1 — spectral canvas: live fit overlay vs. raw PSD (+4 context
%            traces) + up to 3 corner-frequency lines (FC1/FC2/FC3, read
%            straight from the current fitCfg.entryParams — always in
%            sync with the spinner panel, no separate corner-frequency
%            guess/heuristic needed anymore).
%   panel2 — sidebar (scrollable): parameter spinners (panel3, one per
%            kernel_specparam_segmented_multiexp arg — OFF/EXP1-3/FC1-3/
%            CF*/PW*/BW*) / Pointer bus (panel5, chan+t single-select
%            listboxes — replaces the old raw uispinner pair) / controls
%            (panel4: output-label field, one-shot Fit, split Fit_ap/
%            Fit_pe, Save, null-peaks).

    % CFG HEADER
    fRange_start = 1;
    fRange_end   = 250;

    % Sidebar dimensions mirror nexFigure_lda's own reference sizes
    % (wRight=260/wInner=250, hPtr=150, hBtn=30) — the original bespoke
    % sizes here (185 wide sidebar, 160-wide sub-panels, 20px fields,
    % 25px buttons) were cramped enough to be hard to use, especially the
    % Pointer listboxes.
    wInner  = 250;
    xInner  = 5;
    wRight  = wInner + 2 * xInner;   % 260
    xRight  = 5 + 700 + 5;           % canvas (700) + gaps either side
    hBtn     = 30;
    hPtr     = 150;
    hLabel   = 22;
    hCaption = 18;    % "Pointer" caption row — see panel5 note below
    gap      = 5;

    nexObj.Figure.fh = uifigure("Position", [100, 1260, xRight + wRight + 5, 720], "Color", [0, 0, 0]);

    % ── Canvas ───────────────────────────────────────────────────────────
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh, "Position", [5, 5, 700, 680], "BackgroundColor", [0, 0, 0]);

    % ── Sidebar ──────────────────────────────────────────────────────────
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh, "Position", [xRight, 5, wRight, 710], ...
        "BackgroundColor", [0, 0, 0], "Scrollable", "on");

    % Bottom-to-top stack: controls (panel4) / Pointer caption+panel5 / spinners (panel3)
    hControls = hLabel + gap + hBtn + gap + hBtn + gap + hBtn + gap + hBtn + gap;   % label row + 4 button rows
    yControls = xInner;
    yPointer  = yControls + hControls + gap;
    yCaption  = yPointer  + hPtr      + gap;
    yParams   = yCaption  + hCaption  + gap;
    hParams   = 710 - yParams - xInner;

    nexObj.Figure.panel4.ph = uipanel(nexObj.Figure.panel2.ph, "Position", [xInner, yControls, wInner, hControls], ...
        "BackgroundColor", [0, 0, 0]);
    % No "Title" here — nexObj_listCfgPanel nests its own titled sub-panel
    % (one per Pointer key) inside whatever it's given, and that sub-panel's
    % own geometry (h_ph-10 tall, starting at y=5) runs almost all the way
    % to THIS panel's top edge, leaving no room for a second title bar —
    % the two would overlap. A plain caption label above it avoids the
    % double-title stack entirely.
    uilabel(nexObj.Figure.panel2.ph, "Text", "Pointer", ...
        "Position", [xInner, yCaption, wInner, hCaption], ...
        "FontColor", nexObj.nexon.settings.Colors.cyberGreen, "FontWeight", "bold");
    nexObj.Figure.panel5.ph = uipanel(nexObj.Figure.panel2.ph, "Position", [xInner, yPointer, wInner, hPtr], ...
        "BackgroundColor", [0, 0, 0]);
    nexObj.Figure.panel3.ph = uipanel(nexObj.Figure.panel2.ph, "Position", [xInner, yParams, wInner, hParams], ...
        "BackgroundColor", [0, 0, 0], "Scrollable", "on", "Title", "Fit Params", ...
        "ForegroundColor", nexObj.nexon.settings.Colors.cyberGreen);

    cfgEntryChangedFcn = str2func("cfgEntryChanged");
    % breakoutCfgFields_spinner sizes each label/field row as
    % panelH/entryHeightScaler — a FIXED divisor here means row height
    % shrinks with whatever hParams happens to be (this is what made them
    % "too thin" after panel3 got shorter than the original layout's
    % ~630px). Compute it from hParams instead, targeting a constant
    % ~22px row height regardless of container size.
    entryFormArgs.entryHeightScaler = hParams / 22;
    entryFormArgs.cfgFieldName      = "fitCfg";
    nexObj.Figure.panel2 = nexObj_cfgPanel_spinner(nexObj.nexon, nexObj, nexObj.Figure.panel3, ...
        nexObj.fitCfg.entryParams, cfgEntryChangedFcn, entryFormArgs);

    % ── Pointer bus panel — chan/t navigation (single-select each) ────────
    nexObj_listCfgPanel(nexObj.nexon, struct('ph', nexObj.Figure.panel5.ph), nexObj.collector.Pointer, [1, 1]);

    % ── Controls: output label / Fit / Fit_ap+Fit_pe / Save / null-peaks ──
    % Top-to-bottom: one-shot full Fit, then the split Fit_ap/Fit_pe pair,
    % then Save, then null-peaks.
    yLabel = hControls - hLabel;   % top row
    yBtn4  = yLabel - gap - hBtn;  % Fit (one-shot, full width)
    yBtn3  = yBtn4  - gap - hBtn;  % Fit_ap | Fit_pe
    yBtn2  = yBtn3  - gap - hBtn;  % Save (full width)
    yBtn1  = yBtn2  - gap - hBtn;  % null pk (full width)
    wBtn   = round((wInner - 2*xInner - gap) / 2);

    nexObj.Figure.outputLabelField = uieditfield(nexObj.Figure.panel4.ph, "text", ...
        "Position",        [xInner, yLabel, wInner - 2*xInner, hLabel], ...
        "Placeholder",      "output label (required to Save)", ...
        "BackgroundColor",  [0.12 0.12 0.12], ...
        "FontColor",        nexObj.nexon.settings.Colors.cyberGreen, ...
        "ValueChangedFcn",  @(src, ~) onOutputLabelChanged(src, nexObj));
    onOutputLabelChanged(nexObj.Figure.outputLabelField, nexObj);   % seed lastOutputLabel from the (blank) starting value

    nexObj.Figure.regenerateButton = uibutton(nexObj.Figure.panel4.ph, ...
        "Position",         [xInner, yBtn4, wInner - 2*xInner, hBtn], ...
        "Text",             "Fit", ...
        "BackgroundColor",  [0.20 0.20 0.20], ...
        "FontColor",        nexObj.nexon.settings.Colors.cyberGreen, ...
        "ButtonPushedFcn",  @(~, ~) nexObj.regenerateFit());

    nexObj.Figure.fitApButton = uibutton(nexObj.Figure.panel4.ph, ...
        "Position",         [xInner, yBtn3, wBtn, hBtn], ...
        "Text",             "Fit_ap", ...
        "BackgroundColor",  [0.20 0.20 0.20], ...
        "FontColor",        nexObj.nexon.settings.Colors.cyberGreen, ...
        "ButtonPushedFcn",  @(~, ~) nexObj.fitAperiodic());

    nexObj.Figure.fitPeButton = uibutton(nexObj.Figure.panel4.ph, ...
        "Position",         [xInner + wBtn + gap, yBtn3, wBtn, hBtn], ...
        "Text",             "Fit_pe", ...
        "BackgroundColor",  [0.20 0.20 0.20], ...
        "FontColor",        nexObj.nexon.settings.Colors.cyberGreen, ...
        "ButtonPushedFcn",  @(~, ~) nexObj.fitPeriodic());

    nexObj.Figure.saveButton = uibutton(nexObj.Figure.panel4.ph, ...
        "Position",         [xInner, yBtn2, wInner - 2*xInner, hBtn], ...
        "Text",             "Save", ...
        "BackgroundColor",  nexObj.nexon.settings.Colors.cyberGreen, ...
        "ButtonPushedFcn",  @(src, event) nexObj.saveFit(src, event));

    nexObj.Figure.nullPeaksButton = uicontrol(nexObj.Figure.panel4.ph, ...
        "Style",            "pushbutton", ...
        "String",           "null pk", ...
        "Position",         [xInner, yBtn1, wInner - 2*xInner, hBtn], ...
        "BackgroundColor",  nexObj.nexon.settings.Colors.cyberGrey, ...
        "Callback",         @(src, event) nexObj.nullifyPeaks(src, event));

    % ── Spectral canvas ─────────────────────────────────────────────────
    nexObj.Figure.panel1.tiles.t    = tiledlayout(nexObj.Figure.panel1.ph, 1, 1);
    nexObj.Figure.panel1.tiles.Axes.fitScp = nexttile(nexObj.Figure.panel1.tiles.t);
    ax_canvas = nexObj.Figure.panel1.tiles.Axes.fitScp;
    hold(ax_canvas, "on");

    [ptr_chans, ptr_t] = nexObj.currentPtr();
    f = nexObj.DF_postOp.ax.f;
    n_t     = numel(nexObj.DF_postOp.ax.t);
    n_chans = numel(nexObj.DF_postOp.ax.chans);
    ptr_t_pre      = mod(ptr_t - 2, n_t) + 1;
    ptr_t_post     = mod(ptr_t,     n_t) + 1;
    ptr_chans_pre  = mod(ptr_chans - 2, n_chans) + 1;
    ptr_chans_post = mod(ptr_chans,     n_chans) + 1;

    fCond = (f > fRange_start & f < fRange_end);
    f_log = log10(f(fCond));
    numTicks = 30;
    f_ticks  = logspace(log10(f_log(1)), log10(f_log(end)), numTicks);

    nexObj.DF_postOp.df_fit    = nexObj.fitCfg.kernel(nexObj.DF_postOp.ax, nexObj.fitCfg.entryParams);
    nexObj.DF_postOp.df_fit_ap = nexObj.fitCfg.kernel(nexObj.DF_postOp.ax, ...
        spcpmIO_nullifyPeaks(nexObj.fitCfg.entryParams));

    nexObj.Figure.panel1.tiles.graphics.canvas_fit = plot(ax_canvas, f_log, ...
        nexObj.DF_postOp.df_fit(fCond), "Color", nexObj.nexon.settings.Colors.cyberRed);
    nexObj.Figure.panel1.tiles.graphics.canvas_fit.Parent.XTick      = f_ticks;
    nexObj.Figure.panel1.tiles.graphics.canvas_fit.Parent.XTickLabel = 10 .^ f_ticks;
    % Aperiodic-only overlay (peaks nulled) — white, so it reads distinctly
    % against the red full-fit and green raw-signal traces.
    nexObj.Figure.panel1.tiles.graphics.canvas_fit_ap = plot(ax_canvas, f_log, ...
        nexObj.DF_postOp.df_fit_ap(fCond), "Color", [1 1 1], "LineStyle", "--");
    nexObj.Figure.panel1.tiles.graphics.canvas_sig = plot(ax_canvas, f_log, ...
        squeeze(nexObj.DF_postOp.df(ptr_chans, fCond, ptr_t)), "Color", nexObj.nexon.settings.Colors.cyberGreen, "LineWidth", 1.5);
    nexObj.Figure.panel1.tiles.graphics.canvas_context1 = plot(ax_canvas, f_log, ...
        squeeze(nexObj.DF_postOp.df(ptr_chans, fCond, ptr_t_pre)), "Color", [0.2510 0.3569 0.4000]);
    nexObj.Figure.panel1.tiles.graphics.canvas_context2 = plot(ax_canvas, f_log, ...
        squeeze(nexObj.DF_postOp.df(ptr_chans, fCond, ptr_t_post)), "Color", [0 0.2588 0.3608]);
    nexObj.Figure.panel1.tiles.graphics.canvas_context3 = plot(ax_canvas, f_log, ...
        squeeze(nexObj.DF_postOp.df(ptr_chans_pre, fCond, ptr_t)), "Color", [0.4510 0.4157 0.3137]);
    nexObj.Figure.panel1.tiles.graphics.canvas_context4 = plot(ax_canvas, f_log, ...
        squeeze(nexObj.DF_postOp.df(ptr_chans_post, fCond, ptr_t)), "Color", [0.3608 0.2706 0]);

    % Corner-frequency lines — one per FC1/FC2/FC3, straight from
    % entryParams (always in sync with the spinner panel).
    cornerColors = {nexObj.nexon.settings.Colors.cyberGreen, ...
                     nexObj.nexon.settings.Colors.cyberGreen, ...
                     nexObj.nexon.settings.Colors.cyberGreen};
    for k = 1:3
        fld = sprintf("FC%d", k);
        fcID = sprintf("canvas_cornerFreq%d", k);
        try
            fcVal = nexObj.fitCfg.entryParams.(fld);
            nexObj.Figure.panel1.tiles.graphics.(fcID) = xline(ax_canvas, log10(max(fcVal, eps)), ...
                "Color", cornerColors{k});
        catch
        end
    end

    colorAx_green(ax_canvas);
end


% ── Helpers ──────────────────────────────────────────────────────────────

function onOutputLabelChanged(src, nexObj)
    nexObj.lastOutputLabel = string(regexprep(strtrim(src.Value), '[^a-zA-Z0-9_]', '_'));
end
