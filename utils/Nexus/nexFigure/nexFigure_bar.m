function nexFigure_bar(obj)
% Figure for nexObj_bar — a single nested-bar-chart canvas (no tabs).
%
% Layout (960 × 600):
%   Left  (690px) — canvas: one nested bar chart for the active SRC result
%   Right (255px) — View panel   (SRC/CTG/VW/CLR side-by-side in ONE
%                                 container, via nex_buildCollectorViewPanel
%                                 — same mechanism nexFigure_lda etc. use,
%                                 rather than nexObj_bar's old bespoke
%                                 stack of four separate uipanels)
%                   Pointer panel (axis navigation, rebuilt on SRC change)
%
% Uses uifigure (consistent with other nexObject figures).

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
    hView  = 175;   % matches nexFigure_lda's own View panel height
    gap    = 5;

    % ── Right sidebar ──────────────────────────────────────────────────────

    % View panel — SRC/CTG/VW/CLR side-by-side in one container, same
    % nex_buildCollectorViewPanel call every other collector.View-based
    % figure uses; wires each listbox to the generic listCfgEntryChanged
    % (SRC gets its own dispatch, srcSelChanged -> obj.applySRC, internally).
    % SRC is single-select; CTG/VW/CLR default to full multi-select
    % (numel(vals)) when omitted from maxSels, same as before.
    yView = 600 - 5 - hView;
    pan_view = uipanel(fh, ...
        'Position',        [xRight, yView, wRight, hView], ...
        'BackgroundColor', BLACK, ...
        'Title',           'View', ...
        'ForegroundColor', GREEN, ...
        'Scrollable',      'on');
    viewMaxSels.SRC = 1;
    nex_buildCollectorViewPanel(obj, pan_view, hView, viewMaxSels);

    % Pointer container — rebuilt by rebuildPointerPanel on SRC change.
    % Freed-up height from collapsing the four stacked View panels into
    % one row above goes here.
    yPtr = 5;
    hPtr = yView - gap - yPtr;
    pan_ptr = uipanel(fh, ...
        'Position',        [xRight, yPtr, wRight, hPtr], ...
        'BackgroundColor', BLACK, ...
        'Title',           'Pointer', ...
        'ForegroundColor', GREEN, ...
        'Scrollable',      'on');
    obj.Figure.ptrContainer = pan_ptr;

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
    ylabel(ax, 'Balanced accuracy', 'Color', GREEN);
end


% ── Helpers ───────────────────────────────────────────────────────────────────

function GREEN = resolveGreen(obj)
    try
        GREEN = obj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end
