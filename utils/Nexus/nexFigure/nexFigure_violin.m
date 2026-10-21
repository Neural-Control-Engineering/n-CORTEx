function nexFigure_violin(obj)
% Figure for nexObj_violin — a single violin-group canvas (no tabs).
% Mirrors nexFigure_bar.m's layout/mechanism closely (same View/Pointer
% panel construction) — the one addition is a "Build violin" button,
% needed only for the ctg-sourced ("pure analysis") entry point: that
% path's data doesn't exist yet at figure-build time (unlike the
% mdlObj-sourced path, which already has RESULTS rows to list in SRC the
% moment it's wired in) — see nexObj_violin.compileAndVisualize.
%
% Layout (960 x 600):
%   Left  (690px) — canvas: one violin-group chart for the active SRC result
%   Right (255px) — View panel    (SRC/CTG/VW/CLR side-by-side in ONE
%                                  container, via nex_buildCollectorViewPanel)
%                    Build violin  (ctg-sourced path only, no-op otherwise)
%                    Pointer panel (axis navigation, rebuilt on SRC change)

    BLACK = [0 0 0];
    GREEN = resolveGreen(obj);

    fh = uifigure( ...
        'Position',  [200, 200, 960, 600], ...
        'Color',     BLACK, ...
        'Name',      char(obj.headline));
    obj.Figure.fh = fh;
    obj.applyHeadline();

    wRight = 255;
    xRight = 960 - wRight - 5;
    hView  = 175;   % matches nexFigure_lda's/nexFigure_bar's own View panel height
    hBtn   = 30;
    gap    = 5;

    % ── Right sidebar ──────────────────────────────────────────────────────

    yView = 600 - 5 - hView;
    pan_view = uipanel(fh, ...
        'Position',        [xRight, yView, wRight, hView], ...
        'BackgroundColor', BLACK, ...
        'Title',           'View', ...
        'ForegroundColor', GREEN, ...
        'Scrollable',      'on');
    viewMaxSels.SRC = 1;
    nex_buildCollectorViewPanel(obj, pan_view, hView, viewMaxSels);

    % "Build violin" — ctg-sourced path only. isempty(obj.source) is true
    % exactly when this is the ctg-sourced entry point (the mdlObj-sourced
    % constructor always wireModelSource()s a real source) — harmless,
    % clearly-labeled no-op button otherwise rather than hiding/omitting
    % it conditionally, since that would need the SAME isMdlSource check
    % duplicated here just to decide whether to lay the button out at all.
    yBuild = yView - gap - hBtn;
    obj.Figure.buildButton = uibutton(fh, ...
        'Position',        [xRight, yBuild, wRight, hBtn], ...
        'Text',            'Build violin (ctg-sourced only)', ...
        'BackgroundColor', BLACK, ...
        'FontColor',       GREEN, ...
        'ButtonPushedFcn', @(~,~) onBuildViolin(obj));

    % Pointer panel — same outer-shell/inner-content split as
    % nexFigure_bar.m (rebuildPointerPanel clears only the inner panel).
    % Grouping beyond CTG has no "reverse order" concept here -- unlike
    % nexObj_bar, violin's Pointer selections never create extra group
    % tiers of their own (see nexVisualization_violin.m), so there's
    % nothing to reverse.
    yPtr = 5;
    hPtr = yBuild - gap - yPtr;
    pan_ptr = uipanel(fh, ...
        'Position',        [xRight, yPtr, wRight, hPtr], ...
        'BackgroundColor', BLACK, ...
        'Title',           'Pointer', ...
        'ForegroundColor', GREEN);
    pan_ptr_inner = uipanel(pan_ptr, ...
        'Position',        [1, 1, wRight - 2, hPtr - 23], ...
        'BackgroundColor', BLACK, ...
        'BorderType',      'none', ...
        'Scrollable',      'on');
    obj.Figure.ptrContainer = pan_ptr_inner;

    % ── Left: canvas ────────────────────────────────────────────────────────
    wLeft = xRight - 10;
    pan_canvas = uipanel(fh, ...
        'Position',        [5, 5, wLeft, 590], ...
        'BackgroundColor', BLACK);
    obj.Figure.panel0.ph = pan_canvas;
    obj.Figure.panel0.tiles.t = tiledlayout(pan_canvas, 1, 1, ...
        'TileSpacing', 'compact', 'Padding', 'compact');
    ax = nexttile(obj.Figure.panel0.tiles.t);
    obj.Figure.panel0.tiles.ax = ax;
    ax.Color     = BLACK;
    ax.XColor    = GREEN;
    ax.YColor    = GREEN;
    ax.GridColor = GREEN;
    ax.GridAlpha = 0.12;
    ax.Box       = 'on';
    ax.FontSize  = 9;
    grid(ax, 'on');
    hold(ax, 'on');
    ylabel(ax, 'df', 'Color', GREEN);
end


% ── Helpers ───────────────────────────────────────────────────────────────────

function onBuildViolin(obj)
    if isempty(obj.source)
        obj.compileAndVisualize();
    else
        fprintf('[nexFigure_violin] Build violin is a no-op on the mdlObj-sourced path -- RESULTS already arrive via push()/storeResult().\n');
    end
end

function GREEN = resolveGreen(obj)
    try
        GREEN = obj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end
