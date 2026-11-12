function A = nexAudit_commonMode(nexon, trialIdx, opts)
% nexAudit_commonMode  Single-trial visual audit of nexOp_commonMode. Read-only.
%
% A = nexAudit_commonMode(nexon)                 % current router trial
% A = nexAudit_commonMode(nexon, 916)            % DTS row 916
% A = nexAudit_commonMode(nexon, 916, tMark=3.5, tLim=[2.5 4.5])
%
% Reads ONE trial through dtsIO_readDF using the live nexon, runs both
% nexOp_commonMode outputs in memory, and plots raw vs common-mode-removed LFP.
% Writes nothing to the DTS or to disk.
%
%   dfID     : source dfID                               (default "lfp")
%   nTraces  : channels in the stacked panel, spread down the probe (default 12)
%   tMark    : time to mark, in the DF's own t units, e.g. withdrawal.
%              Default = time of the largest |common mode| in the trial.
%   tWin_s   : half-width around tMark for the per-channel RMS panel (default 0.1)
%   tLim     : [t0 t1] x-limits for the time panels      (default interior)
%   edge_s   : seconds excluded at each trial end from the auto mark, variance,
%              color scale and spectra; raw lfp has a sharp edge transient
%              (default 0.25)
%
% A : checks + the two DFs.
%   A.maxReconErr  : max |raw - (cmr + cm)|; should be ~0
%   A.maxCmrMedian : max |median across channels of cmr|; should be ~0
%   A.fracVarCM    : median fraction of channel variance removed (interior)

    arguments
        nexon
        trialIdx = []
        opts.dfID    (1,1) string = "lfp"
        opts.nTraces (1,1) double = 12
        opts.tMark   (1,:) double = []
        opts.tWin_s  (1,1) double = 0.1
        opts.tLim    (1,:) double = []
        opts.edge_s  (1,1) double = 0.25
    end

    if isempty(trialIdx)
        ridx = nex_getRouterIdx(nexon);
        if islogical(ridx), ridx = find(ridx); end
        if isempty(ridx), error('nexAudit_commonMode:noTrial', 'router matches no trial.'); end
        trialIdx = ridx(1);
    end

    DF = dtsIO_readDF(nexon, opts.dfID, trialIdx);
    if ~isstruct(DF) || ~isfield(DF, 'df') || isempty(DF.df)
        error('nexAudit_commonMode:noData', 'no %s data on row %d.', opts.dfID, trialIdx);
    end

    a = struct('outMode', 1, 'useMedian', 1, 'chanRange_start', 1, 'chanRange_end', 384);
    R = nexOp_commonMode(DF, a);
    a.outMode = 2;
    C = nexOp_commonMode(DF, a);

    t   = DF.ax.t(:)';
    X   = double(DF.df(1:size(R.df, 1), :));
    Y   = R.df;
    cm  = C.df;
    nC  = size(X, 1);
    Fs  = 1 / median(diff(t));
    inner = t >= t(1) + opts.edge_s & t <= t(end) - opts.edge_s;

    if isempty(opts.tMark)
        [~, iPk] = max(abs(cm) .* inner);
        tMark = t(iPk);
        markLabel = 'max |CM|';
    else
        tMark = opts.tMark;
        markLabel = 'tMark';
    end
    tLim = opts.tLim;
    if isempty(tLim), tLim = [t(find(inner, 1)), t(find(inner, 1, 'last'))]; end
    inWin = abs(t - tMark) <= opts.tWin_s;

    % ── Checks ────────────────────────────────────────────────────────────
    varRaw = var(X(:, inner), 0, 2);
    A.trialIdx     = trialIdx;
    A.sizeIn       = size(DF.df);
    A.sizeCMR      = size(Y);
    A.sizeCM       = size(cm);
    A.maxReconErr  = max(abs(X - (Y + cm)), [], 'all');
    A.maxCmrMedian = max(abs(median(Y, 1)));
    A.fracVarCM    = median(1 - var(Y(:, inner), 0, 2) ./ varRaw, 'omitnan');
    edgeRatio      = max(abs(cm(~inner))) / max(abs(cm(inner)));
    A.edgeRatio    = edgeRatio;
    A.rmsAtMark    = [median(rms(X(:, inWin), 2)), median(rms(Y(:, inWin), 2))];
    A.tMark        = tMark;
    A.CMR = R;  A.CM = C;
    fprintf(['[nexAudit_commonMode] trial %d, %s: in %s -> cmr %s, cm %s\n' ...
             '  max |raw - (cmr+cm)| = %.2g   max |median(cmr)| = %.2g\n' ...
             '  median variance removed per channel (interior) = %.1f%%\n' ...
             '  edge transient: max |CM| at trial ends is %.1fx the interior max\n' ...
             '  median channel RMS within %.0f ms of %s (t = %.3f): raw %.3g -> cmr %.3g\n'], ...
        trialIdx, opts.dfID, mat2str(A.sizeIn), mat2str(A.sizeCMR), mat2str(A.sizeCM), ...
        A.maxReconErr, A.maxCmrMedian, 100*A.fracVarCM, edgeRatio, 1e3*opts.tWin_s, markLabel, tMark, ...
        A.rmsAtMark(1), A.rmsAtMark(2));

    % ── Figure ────────────────────────────────────────────────────────────
    cRaw = [0.165 0.47 0.84];  cCMR = [0.92 0.41 0.20];  cCM = [0.11 0.69 0.48];
    lim  = prctile(abs(X(:, inner)), 99.5, 'all');
    dmap = [linspace(0.165,0.93,128)', linspace(0.47,0.93,128)', linspace(0.84,0.93,128)'; ...
            linspace(0.93,0.92,128)',  linspace(0.93,0.41,128)', linspace(0.93,0.20,128)'];

    f = figure('Name', sprintf('commonMode audit, trial %d', trialIdx), 'Color', 'w', ...
               'Position', [50 50 1500 880]);
    tl = tiledlayout(f, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('%s, trial %d: nexOp\\_commonMode (dotted line = %s)', ...
          strrep(opts.dfID, '_', '\_'), trialIdx, markLabel));

    ax1 = nexttile(tl);
    imagesc(ax1, t, 1:nC, X, [-lim lim]); axis(ax1, 'xy'); colormap(ax1, dmap);
    xline(ax1, tMark, ':k'); title(ax1, '1. Raw LFP'); xlabel(ax1, 't (s)'); ylabel(ax1, 'channel');
    colorbar(ax1);

    ax2 = nexttile(tl);
    imagesc(ax2, t, 1:nC, Y, [-lim lim]); axis(ax2, 'xy'); colormap(ax2, dmap);
    xline(ax2, tMark, ':k'); title(ax2, '2. Common mode removed (same color scale)');
    xlabel(ax2, 't (s)'); colorbar(ax2);

    ax3 = nexttile(tl);
    plot(ax3, t, cm, 'Color', cCM, 'LineWidth', 1);
    ylim(ax3, 1.1 * max(abs(cm(inner))) * [-1 1]);
    xline(ax3, tMark, ':k'); title(ax3, '3. Common-mode trace (probe median)');
    xlabel(ax3, 't (s)'); box(ax3, 'off');

    ax4 = nexttile(tl); hold(ax4, 'on');
    chSel = unique(round(linspace(1, nC, min(opts.nTraces, nC))));
    tm = t >= tLim(1) & t <= tLim(2);
    sp = 1.2 * max(max(X(chSel, tm), [], 2) - min(X(chSel, tm), [], 2));
    if sp == 0, sp = 1; end
    for i = 1:numel(chSel)
        plot(ax4, t(tm), X(chSel(i), tm) + (i-1)*sp, 'Color', cRaw, 'LineWidth', 0.75);
        plot(ax4, t(tm), Y(chSel(i), tm) + (i-1)*sp, 'Color', cCMR, 'LineWidth', 0.75);
    end
    xline(ax4, tMark, ':k');
    set(ax4, 'YTick', (0:numel(chSel)-1)*sp, 'YTickLabel', compose("ch%d", chSel));
    xlim(ax4, tLim); ylim(ax4, [-sp, numel(chSel)*sp]); box(ax4, 'off');
    title(ax4, '4. Channels down the probe (blue raw, orange removed)'); xlabel(ax4, 't (s)');

    ax5 = nexttile(tl); hold(ax5, 'on');
    plot(ax5, 1:nC, rms(X(:, inWin), 2), 'Color', cRaw, 'LineWidth', 1.5, 'DisplayName', 'raw');
    plot(ax5, 1:nC, rms(Y(:, inWin), 2), 'Color', cCMR, 'LineWidth', 1.5, 'DisplayName', 'common mode removed');
    title(ax5, sprintf('5. RMS by channel within %.0f ms of the mark', 1e3*opts.tWin_s));
    xlabel(ax5, 'channel'); ylabel(ax5, 'RMS'); legend(ax5, 'Box', 'off', 'Location', 'east'); box(ax5, 'off');

    ax6 = nexttile(tl); hold(ax6, 'on');
    nW = min(512, 2^floor(log2(nnz(inner)/4)));
    [pX, fx] = pwelch(X(:, inner)', nW, nW/2, nW, Fs);
    pY = pwelch(Y(:, inner)', nW, nW/2, nW, Fs);
    pC = pwelch(cm(inner)', nW, nW/2, nW, Fs);
    plot(ax6, fx, 10*log10(median(pX, 2)), 'Color', cRaw, 'LineWidth', 1.5, 'DisplayName', 'raw (median channel)');
    plot(ax6, fx, 10*log10(median(pY, 2)), 'Color', cCMR, 'LineWidth', 1.5, 'DisplayName', 'removed (median channel)');
    plot(ax6, fx, 10*log10(pC), 'Color', cCM, 'LineWidth', 1.5, 'DisplayName', 'common-mode trace');
    xlim(ax6, [0 120]); title(ax6, '6. Whole-trial spectra'); xlabel(ax6, 'Hz'); ylabel(ax6, 'dB');
    legend(ax6, 'Box', 'off'); box(ax6, 'off');

    linkaxes([ax1 ax2 ax3], 'x');
    xlim(ax1, tLim);
end
