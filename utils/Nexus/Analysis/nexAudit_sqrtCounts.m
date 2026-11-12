function A = nexAudit_sqrtCounts(nexon, trialIdx, opts)
% nexAudit_sqrtCounts  Single-trial visual audit of nexOp_sqrtCounts. Read-only.
%
% A = nexAudit_sqrtCounts(nexon)                 % current router trial
% A = nexAudit_sqrtCounts(nexon, 412)            % DTS row 412
% A = nexAudit_sqrtCounts(nexon, 412, nTraces=16, tLim=[2 6])
%
% Reads ONE trial through dtsIO_readDF using the live nexon, runs
% nexOp_sqrtCounts in memory, and plots the input measure=rate against the
% output in polyGraph-style stacks, for units spread down the probe. Writes
% nothing to the DTS or to disk.
%
%   dfID        : source dfID                      (default "RTS_spk_activity")
%   binWidth_ms : passed to nexOp_sqrtCounts       (default 50)
%   nTraces     : units shown, evenly spaced in depth (default 12)
%   units       : explicit unit row indices; overrides nTraces
%   tLim        : [t0 t1] x-limits in the DF's own t units (default full trial)
%
% A : checks + selected units + the transformed DF.
%   A.maxNonInteger  : max |y^2 - round(y^2)| over all units; should be ~0
%   A.spikesIn/Out   : raster spikes in kept bins vs sum(y^2); should match
%   A.bestLag_bins   : lag of peak rate-vs-count correlation; should be 0

    arguments
        nexon
        trialIdx = []
        opts.dfID        (1,1) string = "RTS_spk_activity"
        opts.binWidth_ms (1,1) double = 50
        opts.nTraces     (1,1) double = 12
        opts.units       (1,:) double = []
        opts.tLim        (1,:) double = []
    end

    if isempty(trialIdx)
        ridx = nex_getRouterIdx(nexon);
        if islogical(ridx), ridx = find(ridx); end
        if isempty(ridx), error('nexAudit_sqrtCounts:noTrial', 'router matches no trial.'); end
        trialIdx = ridx(1);
    end

    DF = dtsIO_readDF(nexon, opts.dfID, trialIdx);
    if ~isstruct(DF) || ~isfield(DF, 'df') || isempty(DF.df)
        local_diagnoseMissing(nexon.console.BASE.DTS, opts.dfID, trialIdx);
        error('nexAudit_sqrtCounts:noData', 'no %s data on row %d (details above).', opts.dfID, trialIdx);
    end
    meas = string(DF.ax.measure);
    raster = double(DF.df(:, :, meas == "raster"));
    rate   = double(DF.df(:, :, meas == "rate"));
    t_in   = DF.ax.t(:)';

    OUT   = nexOp_sqrtCounts(DF, struct('binWidth_ms', opts.binWidth_ms));
    t_out = OUT.ax.t(:)';
    Y     = OUT.df;
    nPer  = round(opts.binWidth_ms / 1e3 / median(diff(t_in)));
    nB    = size(Y, 2);
    nKeep = nB * nPer;

    % ── Unit selection: active units, evenly spaced in depth ─────────────
    if isfield(DF.ax, 'chans'), depth = double(DF.ax.chans(:)); else, depth = (1:size(Y,1))'; end
    if isempty(opts.units)
        active = find(sum(raster, 2) > 0);
        [~, ord] = sort(depth(active));
        active = active(ord);
        sel = active(unique(round(linspace(1, numel(active), min(opts.nTraces, numel(active))))));
    else
        sel = opts.units(:);
    end
    n = numel(sel);

    % ── Checks ────────────────────────────────────────────────────────────
    rateBinned = squeeze(mean(reshape(rate(:, 1:nKeep), size(rate,1), nPer, nB), 2));
    counts     = Y.^2;
    lags = -4:4; c = nan(size(lags));
    a = rateBinned(sel, :); b = counts(sel, :);
    for li = 1:numel(lags)
        L = lags(li);
        ia = max(1, 1+L):min(nB, nB+L);  ib = ia - L;
        x = a(:, ia) - mean(a(:, ia), 2);  y = b(:, ib) - mean(b(:, ib), 2);
        c(li) = sum(x .* y, 'all') / sqrt(sum(x.^2, 'all') * sum(y.^2, 'all'));
    end
    [~, iBest] = max(c);

    A.trialIdx      = trialIdx;
    A.units         = sel;
    A.channels      = depth(sel);
    A.sizeIn        = size(DF.df);
    A.sizeOut       = size(Y);
    A.maxNonInteger = max(abs(counts - round(counts)), [], 'all');
    A.spikesIn      = sum(raster(:, 1:nKeep), 'all');
    A.spikesOut     = round(sum(counts, 'all'));
    A.corrLag0      = c(lags == 0);
    A.bestLag_bins  = lags(iBest);
    A.OUT           = OUT;
    fprintf(['[nexAudit_sqrtCounts] trial %d, %s: in %s -> out %s\n' ...
             '  max |y^2 - integer| = %.2g   spikes in/out = %d / %d\n' ...
             '  rate-vs-count corr at lag 0 = %.3f, best lag = %d bin(s)\n'], ...
        trialIdx, opts.dfID, mat2str(A.sizeIn), mat2str(A.sizeOut), A.maxNonInteger, ...
        A.spikesIn, A.spikesOut, A.corrLag0, A.bestLag_bins);

    % ── Figure ────────────────────────────────────────────────────────────
    cIn  = [0.165 0.47 0.84];
    cOut = [0.92 0.41 0.20];
    tLim = opts.tLim;
    if isempty(tLim), tLim = t_in([1 end]); end
    tiMask = t_in >= tLim(1) & t_in <= tLim(2);
    toMask = t_out >= tLim(1) & t_out <= tLim(2);
    labels = compose("u%d ch%d", sel(:), round(depth(sel)));

    f = figure('Name', sprintf('sqrtCounts audit, trial %d', trialIdx), 'Color', 'w', ...
               'Position', [60 60 1500 max(520, 46*n + 120)]);
    tl = tiledlayout(f, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('%s, trial %d: input rate vs nexOp\\_sqrtCounts (%g ms bins)', ...
          strrep(opts.dfID, '_', '\_'), trialIdx, opts.binWidth_ms));

    ax1 = nexttile(tl);
    local_stack(ax1, t_in(tiMask), rate(sel, tiMask), cIn, 1);
    title(ax1, 'Input: measure = rate (Hz, per-trace range shared)');
    set(ax1, 'YTick', local_ticks(ax1, n), 'YTickLabel', labels);

    ax2 = nexttile(tl);
    local_stack(ax2, t_out(toMask), Y(sel, toMask), cOut, 1);
    title(ax2, 'Output: \surd(spike count per bin)');
    set(ax2, 'YTick', local_ticks(ax2, n), 'YTickLabel', labels);

    % Overlay: each trace scaled 0-1 on the kept window, so timing can be compared.
    ax3 = nexttile(tl); hold(ax3, 'on');
    for i = 1:n
        a1 = local_unit(rate(sel(i), tiMask));
        a2 = local_unit(Y(sel(i), toMask));
        plot(ax3, t_in(tiMask), a1 + (i-1)*1.2, 'Color', cIn, 'LineWidth', 1);
        stairs(ax3, t_out(toMask) - opts.binWidth_ms/2e3, a2 + (i-1)*1.2, 'Color', cOut, 'LineWidth', 1);
    end
    title(ax3, 'Overlay, each trace scaled 0–1 (blue rate, orange \surdcount)');
    set(ax3, 'YTick', (0:n-1)*1.2 + 0.5, 'YTickLabel', labels);
    xlim(ax3, tLim); ylim(ax3, [-0.2, n*1.2]); box(ax3, 'off');
    xlabel(ax3, 't (s)');
    linkaxes([ax1 ax2 ax3], 'x');
end


function local_diagnoseMissing(DTS, dfID, trialIdx)
% dtsIO_composeDF swallows HDF5 read errors, so report the cause here: the real
% read error, the spike dfIDs that exist, and which rows carry this dfID.
    fprintf('[nexAudit_sqrtCounts] row %d returned no data for "%s".\n', trialIdx, dfID);
    try
        dtsIO_readHDF5(DTS, char(dfID), trialIdx, []);
        fprintf('  direct HDF5 read: no error (group absent or empty on this row)\n');
    catch e
        fprintf('  direct HDF5 read error: %s\n', e.message);
    end
    try
        ids = string(dtsIO_listDFIDs(DTS));
        fprintf('  spike dfIDs in this DTS: %s\n', strjoin(ids(contains(ids, "spk")), ', '));
    catch e
        fprintf('  could not list dfIDs: %s\n', e.message);
    end

    % Rows carrying the dfID. Read-only, one open per file, as nexTract does.
    has = false(height(DTS), 1);
    pathCol = 'h5_path';
    if ismember(char("h5_path_" + dfID), DTS.Properties.VariableNames), pathCol = char("h5_path_" + dfID); end
    paths = string(DTS.(pathCol));
    for p = unique(paths(strlength(paths) > 0))'
        fapl = H5P.create('H5P_FILE_ACCESS');
        H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
        fid = H5F.open(char(p), 'H5F_ACC_RDONLY', fapl);
        H5P.close(fapl);
        for r = find(paths == p)'
            try
                has(r) = H5L.exists(fid, char(string(DTS.h5_root(r)) + "/" + dfID + "/df"), 'H5P_DEFAULT');
            catch
            end
        end
        H5F.close(fid);
    end
    fprintf('  rows with "%s": %d of %d\n', dfID, nnz(has), height(DTS));
    if any(has)
        rows = find(has);
        fprintf('  e.g. rows: %s\n', mat2str(rows(unique(round(linspace(1, numel(rows), min(8, numel(rows))))))'));
        if ismember('sessionLabel_subj', DTS.Properties.VariableNames)
            [g, subj] = findgroups(string(DTS.sessionLabel_subj(has)));
            for i = 1:numel(subj)
                fprintf('    %s: %d row(s)\n', subj(i), nnz(g == i));
            end
        end
    end
end

function local_stack(ax, t, X, col, lw)
% polyGraph layout: trace i at (i-1) * 1.2 * largest trace range.
    hold(ax, 'on');
    sp = 1.2 * max(max(X, [], 2) - min(X, [], 2));
    if sp == 0, sp = 1; end
    for i = 1:size(X, 1)
        plot(ax, t, X(i, :) + (i-1)*sp, 'Color', col, 'LineWidth', lw);
    end
    ax.UserData = sp;
    xlim(ax, t([1 end])); ylim(ax, [-0.1*sp, size(X,1)*sp]);
    xlabel(ax, 't (s)'); box(ax, 'off');
end

function y = local_ticks(ax, n)
    y = (0:n-1) * ax.UserData;
end

function u = local_unit(x)
    r = max(x) - min(x);
    if r == 0, u = zeros(size(x)); else, u = (x - min(x)) / r; end
end
