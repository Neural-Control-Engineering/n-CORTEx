function R = debugEXT_JOLT_saved(SLRT, focusRows, opts)
% debugEXT_JOLT_saved  Read-only checks on an EXT-saved (post-postEXT_JOLT) SLRT table.
%
% R = debugEXT_JOLT_saved(SLRT)              % summary table + printed flags
% R = debugEXT_JOLT_saved(SLRT, [3 7])       % + one diagnostic figure per row
%
% For the table loaded from Data/EXT/SLRT/<session>.mat. That table is already
% masked by trialMask and has lost the realtime-onset-aligned columns, so this
% checks consistency of what was SAVED rather than replaying evaluatePeak_jolt
% (for a full replay use debugEXT_JOLT on the RAW SLRT).
%
% Event indices index each row's own clock_time (as alignSignals2Events uses
% them), so event e sits at clock_time(e) - clock_time(stimOnset) seconds after
% the onset. Nothing is modified or saved.
%
% R flags
%   gateDup      : trial-gate shared with another row. extSPK gives EVERY row
%                  with that gate the same spikes.
%   gateOrder    : trial-gate not strictly increasing down the rows
%   missing      : responseThreshold / responseDelay / stimOnset / stimPeak empty or NaN
%   negRaw       : responseThreshold < 0 (raw sensor units)
%   negGrams     : responseThreshold >= 0 but responseThreshold_g < 0 (below the
%                  calibration curve)
%   badIndex     : an event index outside its row's clock_time
%   delayConv    : which onset the stored responseDelay matches:
%                  "onset+adv" (postEXT's) or "event" (stimOnsetAdvance column)
%                  -- they differ by 2*advance whenever the UI advance ~= 0
%   threshDiff   : stored responseThreshold minus (lowess at stimPeak - lowess at
%                  the onset postEXT used), from the saved onset-aligned lowess trace

    arguments
        SLRT table
        focusRows (1,:) double = []
        opts.Fs (1,1) double = 1000
        opts.perPage (1,1) double = 12
        opts.doPlot (1,1) logical = true
    end
    Fs = opts.Fs;
    cols = string(SLRT.Properties.VariableNames);
    nR = height(SLRT);
    has = @(c) ismember(c, cols);

    num  = @(c) local_numcol(SLRT, c, nR);
    gate = num("trial-gate");
    on   = num("stimOnset");   pk  = num("stimPeak");
    onA  = num("stimOnsetAdvance");  pkD = num("stimPeakDelay");
    advS = num("stimOnset_advance"); delS = num("stimPeak_delay");
    advS(isnan(advS)) = 0;  delS(isnan(delS)) = 0;
    thr  = num("responseThreshold");  thrG = num("responseThreshold_g");
    rDel = num("responseDelay");

    % ── Event times relative to the auto onset, via each row's clock_time ──
    tOf = nan(nR, 4);  badIdx = false(nR, 1);
    for i = 1:nR
        if ~has("clock_time"), break; end
        ck = SLRT.clock_time{i};
        idx = [on(i), onA(i), pk(i), pkD(i)];
        ok = isfinite(idx) & idx >= 1 & idx <= numel(ck);
        badIdx(i) = any(isfinite(idx) & ~ok);
        if ok(1)
            tOf(i, ok) = ck(idx(ok)) - ck(on(i));
        end
    end
    % responseDelay under each onset convention (postEXT: onset + adv; event: onset - adv)
    delay_postEXT = tOf(:, 4) - advS;          % t(peakDelayed) - t(onset + adv)
    delay_event   = tOf(:, 4) - tOf(:, 2);     % t(peakDelayed) - t(stimOnsetAdvance event)
    conv = strings(nR, 1);
    tol = 1.5 / Fs;
    conv(abs(rDel - delay_postEXT) < tol) = "onset+adv";
    conv(abs(rDel - delay_event)   < tol & conv == "") = "event";
    conv(abs(rDel - delay_event)   < tol & abs(rDel - delay_postEXT) < tol) = "both (adv=0)";
    conv(conv == "" & isfinite(rDel)) = "neither";

    % ── Threshold recheck from the saved onset-aligned lowess trace ─────────
    trCol = "";
    for c = ["stimOnset_aligned_stimLowess", "stimOnset_aligned_stim_raw"]
        if has(c) && has(c + "_time"), trCol = c; break; end
    end
    thrCheck = nan(nR, 1);
    if trCol ~= ""
        for i = 1:nR
            y = SLRT.(trCol){i};  tt = SLRT.(trCol + "_time"){i};
            if isempty(y) || ~isfinite(tOf(i, 3)), continue; end
            yPk = interp1(tt, y, tOf(i, 3), 'nearest');
            yOn = interp1(tt, y, advS(i), 'nearest');
            thrCheck(i) = yPk - yOn;
        end
    end

    [~, ~, gIdx] = unique(gate);
    gCount = accumarray(gIdx(isfinite(gate)), 1);
    R = table((1:nR)', gate, on, onA, pk, pkD, advS, delS, thr, thrG, rDel, ...
        tOf(:,2), tOf(:,3), tOf(:,4), conv, thrCheck, ...
        'VariableNames', {'row','trialGate','stimOnset','stimOnsetAdvance','stimPeak', ...
        'stimPeakDelay','advance_s','delay_s','responseThreshold','responseThreshold_g', ...
        'responseDelay','tOnsetAdvance_s','tPeak_s','tWithdrawal_s','delayConv','thrRecheck'});
    R.gateDup    = isfinite(gate) & gCount(min(gIdx, numel(gCount))) > 1;
    R.gateOrder  = [false; diff(gate) <= 0];
    R.missing    = ~isfinite(thr) | ~isfinite(rDel) | ~isfinite(on) | ~isfinite(pk);
    R.negRaw     = thr < 0;
    R.negGrams   = thr >= 0 & thrG < 0;
    R.badIndex   = badIdx;
    R.threshDiff = thr - thrCheck;

    % ── Summary ──────────────────────────────────────────────────────────
    sess = "";
    if has("session_label"), sess = string(SLRT.session_label{1}); end
    fprintf('[debugEXT_JOLT_saved] %s\n  %d rows, trial-gate %s\n', sess, nR, local_range(gate));
    fprintf('  gate duplicates: %d   gate out of order: %d   missing values: %d   bad event index: %d\n', ...
        nnz(R.gateDup), nnz(R.gateOrder), nnz(R.missing), nnz(R.badIndex));
    fprintf('  responseThreshold < 0: %d   raw >= 0 but grams < 0: %d\n', nnz(R.negRaw), nnz(R.negGrams));
    fprintf('  responseDelay matches: onset+adv %d | event column %d | both (adv=0) %d | neither %d\n', ...
        nnz(conv == "onset+adv"), nnz(conv == "event"), nnz(conv == "both (adv=0)"), nnz(conv == "neither"));
    fprintf('  nonzero UI advance: %d rows (sign question applies)   nonzero UI delay: %d rows\n', ...
        nnz(advS ~= 0), nnz(delS ~= 0));
    if trCol ~= ""
        fprintf('  threshold recheck from %s: median |diff| = %.3g (raw units)\n', trCol, median(abs(R.threshDiff), 'omitnan'));
    end
    fl = find(R.gateDup | R.gateOrder | R.missing | R.negRaw | R.negGrams | R.badIndex | conv == "neither");
    if ~isempty(fl), fprintf('  flagged rows: %s\n', mat2str(fl')); end

    % ── Figures: every trial (or focusRows), stim raw aligned to stimOnset ──
    if ~opts.doPlot, return; end
    plotCol = "";
    for c = ["stimOnset_aligned_stim_raw", "stimOnset_aligned_stimLowess"]
        if has(c) && has(c + "_time"), plotCol = c; break; end
    end
    if plotCol == "", fprintf('  no stimOnset-aligned stim column to plot\n'); return; end
    rows = focusRows;
    if isempty(rows), rows = 1:nR; end
    rows = rows(rows >= 1 & rows <= nR);
    per = opts.perPage;
    for p = 1:ceil(numel(rows) / per)
        local_page(SLRT, plotCol, R, rows((p-1)*per + 1 : min(p*per, numel(rows))), p, sess);
    end
end


% ── helpers ──────────────────────────────────────────────────────────────
function y = local_numcol(T, c, n)
    y = nan(n, 1);
    if ~ismember(c, string(T.Properties.VariableNames)), return; end
    v = T.(c);
    for k = 1:n
        if iscell(v), x = v{k}; else, x = v(k, 1); end
        if (isnumeric(x) || islogical(x)) && ~isempty(x), y(k) = double(x(1)); end
    end
end

function s = local_range(g)
    g = g(isfinite(g));
    if isempty(g), s = 'absent'; else, s = sprintf('%d..%d (%d unique)', min(g), max(g), numel(unique(g))); end
end

function local_page(SLRT, plotCol, R, rows, pageNum, sess)
% One figure per page: a tile per trial, stim aligned to stimOnset, xlines at
% the four stored events (times from each row's clock_time).
    nT = numel(rows);
    nC = min(4, nT);  nRw = ceil(nT / nC);
    f = figure('Color', 'w', 'Position', [40 40 360*nC 230*nRw + 60], ...
               'Name', sprintf('EXT SLRT events, page %d', pageNum));
    tl = tiledlayout(f, nRw, nC, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('%s | %s, t = 0 at stimOnset | page %d', sess, plotCol, pageNum), 'Interpreter', 'none');
    ev = {'stimOnset',        [0.11 0.69 0.48], '-';
          'stimOnsetAdvance', [0.55 0.39 0.82], '--';
          'stimPeak',         [0.92 0.41 0.20], '-';
          'stimPeakDelay',    [0.92 0.41 0.20], '--'};
    for k = 1:nT
        i = rows(k);  r = R(i, :);
        ax = nexttile(tl); hold(ax, 'on');
        y = SLRT.(plotCol){i};  tt = SLRT.(plotCol + "_time"){i};
        if isempty(y)
            text(ax, 0.5, 0.5, 'no trace', 'Units', 'normalized', 'HorizontalAlignment', 'center');
        else
            plot(ax, tt, y, 'Color', [0.165 0.47 0.84], 'LineWidth', 1, 'HandleVisibility', 'off');
        end
        tEv = [0, r.tOnsetAdvance_s, r.tPeak_s, r.tWithdrawal_s];
        for e = 1:4
            if isfinite(tEv(e))
                xline(ax, tEv(e), ev{e, 3}, 'Color', ev{e, 2}, 'LineWidth', 1.25, 'DisplayName', ev{e, 1});
            end
        end
        flagNames = ["dup" "order" "missing" "neg" "negG" "badIdx"];
        fl = flagNames(logical([r.gateDup r.gateOrder r.missing r.negRaw r.negGrams r.badIndex]));
        title(ax, sprintf('row %d, gate %d: %.3g g, %.3f s %s', r.row, r.trialGate, ...
              r.responseThreshold_g, r.responseDelay, strjoin("[" + fl + "]", '')), ...
              'FontSize', 8, 'FontWeight', 'normal', 'Interpreter', 'none');
        lo = min([0, tEv(isfinite(tEv))]) - 0.3;
        hi = max([0, tEv(isfinite(tEv))]) + 0.4;
        xlim(ax, [lo hi]); box(ax, 'off');
        if k == 1
            lg = legend(ax, 'Orientation', 'horizontal', 'Box', 'off', 'Interpreter', 'none');
            lg.Layout.Tile = 'north';
        end
    end
end
