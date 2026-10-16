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

    % Pointer panel — outer shell holds the title bar (with the reverse-
    % order checkbox right-justified into it, below) plus an INNER content
    % panel that rebuildPointerPanel actually clears/rebuilds on SRC
    % change. obj.Figure.ptrContainer points at the inner panel, not this
    % outer one, specifically so rebuildPointerPanel's delete(ph.Children)
    % clears only the listboxes — the checkbox lives as a sibling at the
    % outer level and is never touched by that rebuild.
    yPtr = 5;
    hPtr = yView - gap - yPtr;
    pan_ptr = uipanel(fh, ...
        'Position',        [xRight, yPtr, wRight, hPtr], ...
        'BackgroundColor', BLACK, ...
        'Title',           'Pointer', ...
        'ForegroundColor', GREEN);

    % Reverse expand-axis tier order — flips region/chans vs time (or
    % whichever Pointer-driven axes are currently multi-selected) without
    % touching CTG's own tier order, which stays controlled by its own
    % listbox item order (see nexObj_bar.reverseExpandOrder /
    % resolveExpandAxes in nexVisualization_bar.m). Right-justified into
    % the "Pointer" title-bar row — a uipanel's title text occupies only
    % the top ~20px of its local coordinate space, leaving room alongside
    % it for a right-aligned control.
    cbW = 75; cbH = 15;
    obj.Figure.reverseExpandCB = uicheckbox(pan_ptr, ...
        'Position',        [wRight - cbW - 1, hPtr - 18, cbW, cbH], ...
        'Text',            'Reverse', ...
        'Tooltip',         ['Reverse the outer/inner order of region/chans ' ...
                             'vs time (and any other Pointer-driven expand-' ...
                             'axis) tiers. CTG tier order is unaffected.'], ...
        'FontColor',       GREEN, ...
        'FontSize',        9, ...
        'Value',           obj.reverseExpandOrder, ...
        'ValueChangedFcn', @(src,~) onReverseExpandOrder(obj, src));

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
    ylabel(ax, 'Balanced accuracy', 'Color', GREEN);
end


% ── Helpers ───────────────────────────────────────────────────────────────────

function onReverseExpandOrder(obj, src)
    obj.reverseExpandOrder = logical(src.Value);
    obj.visualize();
end

function GREEN = resolveGreen(obj)
    try
        GREEN = obj.nexon.settings.Colors.cyberGreen;
    catch
        GREEN = [0.18 0.8 0.44];
    end
end
