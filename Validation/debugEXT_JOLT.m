function R = debugEXT_JOLT(slrtSource, focusRows, opts)
% debugEXT_JOLT  Read-only replay of postEXT_JOLT's per-trial event/threshold logic.
%
% R = debugEXT_JOLT(rawSlrtPath)                       % summary table, all trials
% R = debugEXT_JOLT(rawSlrtPath, [3 7])                % + a diagnostic figure per row
% R = debugEXT_JOLT({SLRT, slrtFile}, 3)               % pre-postEXT table already in memory
% R = debugEXT_JOLT(rawSlrtPath, 3, trialMask=[0 1 2 4 5])
%
% rawSlrtPath : the RAW SLRT .mat (same path extractEXT passes to extractEXT_SLRT,
%               e.g. fullfile(params.paths.Data.RAW.SLRT.cloud, session)).
%               Needs the PRE-postEXT table: postEXT removes the rt-onset-aligned
%               stim columns, so an already-saved EXT SLRT cannot be replayed.
% focusRows   : 1-based SLRT rows to plot (row r = trial r-1, as in postEXT).
% trialMask   : 0-based trial numbers from the extraction log (default: all rows).
%
% The per-trial core copies the postEXT_JOLT loop body (lowess 0.01,
% evaluatePeak_jolt, rThresh = maxVal - onsetVal, rDelay = t(peakDelayed) -
% t(onsetAdvanced), the same calibration call), with figTitle = [] so nothing is
% written to ~/Temp. Nothing is saved anywhere.
%
% R : one row per SLRT row, with flags
%   gateMismatch : trial-gate ~= row. spikeGLX tN joins on trial-gate == N+1,
%                  while postEXT/trialMask use row-1, so these must agree.
%   negRaw       : rThresh < 0 in raw sensor units (onset value above max value)
%   negGrams     : rThresh >= 0 raw but < 0 g after calibration (below the curve)
%   advSign      : the onset used for rThresh/rDelay (idxOnset + advance) and the
%                  stimOnsetAdvance EVENT that indexEventAdjustments writes
%                  (idxOnset - advance) disagree. They differ whenever advance ~= 0.
%   evalError    : evaluatePeak_jolt threw (message in R.err)

    arguments
        slrtSource
        focusRows (1,:) double = []
        opts.trialMask (1,:) double = []
        opts.Fs (1,1) double = 1000
    end
    Fs = opts.Fs;

    % ── Load the pre-postEXT SLRT ────────────────────────────────────────
    if iscell(slrtSource)
        SLRT = slrtSource{1};  slrtFile = slrtSource{2};
    else
        [SLRT, slrtFile] = extractEXT_SLRT(slrtSource);
    end
    cols = string(SLRT.Properties.VariableNames);
    if ~ismember("stimOnset_aligned_stim_raw", cols)
        error('debugEXT_JOLT:notRaw', ['SLRT has no stimOnset_aligned_stim_raw column -- this looks like a ' ...
              'post-postEXT table. Pass the RAW SLRT path instead.']);
    end

    % ── Calibration, exactly as postEXT_JOLT ─────────────────────────────
    fit = [];  func = [];
    try, fit = slrtFile.realtimeLog.session.sense.sense1.calibration.LUT.fit; catch, end
    try, func = slrtFile.realtimeLog.session.sense.sense1.calibration.LUT.func; catch, end
    hasTrialFit = ismember("calibFit_vonfrey", cols);
    calib = @(i, x) local_calib(func, fit, hasTrialFit, SLRT, i, x);
    try
        fprintf('[debugEXT_JOLT] calibration maps raw 0 -> %.4g g (row 1 fit)\n', calib(1, 0));
    catch e
        fprintf('[debugEXT_JOLT] calibration check failed: %s\n', e.message);
    end

    nR = height(SLRT);
    mask = opts.trialMask;
    if isempty(mask), mask = 0:nR-1; end

    % ── Replay every trial ───────────────────────────────────────────────
    v = nan(nR, 13);  err = strings(nR, 1);  gate = nan(nR, 1);
    store = cell(nR, 1);
    for i = 1:nR
        try, g = SLRT.("trial-gate")(i); if iscell(g), g = g{1}; end; gate(i) = double(g); catch, end
        if ~ismember(i - 1, mask), continue; end
        try
            stimRaw = SLRT.stimOnset_aligned_stim_raw{i};
            t       = SLRT.stimOnset_aligned_stim_raw_time{i};
            stimSmooth = lowess(stimRaw, 0.01);
            advS  = local_num(SLRT, "stimOnset_advance", i);
            delS  = local_num(SLRT, "stimPeak_delay", i);
            onsetAdvance = round(advS * Fs);
            peakDelay    = round(delS * Fs);
            [~, onsetVal, maxVal, ~, idxPeak, idxPeak_delayed, idxOnset, idxOnset_advanced, ~] = ...
                evaluatePeak_jolt(t, stimSmooth, onsetAdvance, peakDelay, []);
            rDel    = t(idxPeak_delayed) - t(idxOnset_advanced);
            rThresh = maxVal - onsetVal;
            idxOnsetEvent = round(idxOnset - advS * Fs);          % indexEventAdjustments 'Advance'
            v(i, :) = [idxOnset, idxOnset_advanced, idxOnsetEvent, idxPeak, idxPeak_delayed, ...
                       onsetVal, maxVal, rThresh, calib(i, rThresh), rDel, advS, delS, ...
                       find(round(t, 3) == 0, 1)];
            store{i} = struct('t', t, 'raw', stimRaw, 'smooth', stimSmooth);
        catch e
            err(i) = string(e.message);
        end
    end

    R = array2table(v, 'VariableNames', {'idxOnset','idxOnset_advanced','idxOnsetAdvance_event', ...
        'idxPeak','idxPeak_delayed','onsetVal','maxVal','rThresh_raw','rThresh_g','rDelay_s', ...
        'onsetAdvance_s','peakDelay_s','idxRtOnset'});
    R = [table((1:nR)', (0:nR-1)', gate, ismember((0:nR-1)', mask), ...
         'VariableNames', {'row','trialNum0','trialGate','inMask'}), R];
    R.gateMismatch = R.trialGate ~= R.row;
    R.negRaw       = R.rThresh_raw < 0;
    R.negGrams     = R.rThresh_raw >= 0 & R.rThresh_g < 0;
    R.advSign      = isfinite(R.idxOnset_advanced) & R.idxOnset_advanced ~= R.idxOnsetAdvance_event;
    R.evalError    = err ~= "";
    R.err          = err;

    % Stored values, if this table already carries them (side by side, no judgment)
    for c = ["responseThreshold", "responseThreshold_g", "responseDelay", "stimOnset", "stimPeak"]
        if ismember(c, cols)
            R.("stored_" + c) = local_numcol(SLRT.(c));
        end
    end

    % ── Summary ──────────────────────────────────────────────────────────
    m = R.inMask;
    fprintf(['[debugEXT_JOLT] %d rows, %d in mask\n' ...
             '  gate mismatch (trial-gate ~= row): %d   first at row %s\n' ...
             '  rThresh < 0 raw: %d   rThresh >= 0 raw but < 0 g: %d\n' ...
             '  onset advance sign conflict: %d   evaluatePeak errors: %d\n'], ...
        nR, nnz(m), nnz(R.gateMismatch), local_first(R.gateMismatch), ...
        nnz(R.negRaw & m), nnz(R.negGrams & m), nnz(R.advSign & m), nnz(R.evalError & m));
    flagged = find(m & (R.negRaw | R.negGrams | R.advSign | R.evalError));
    if ~isempty(flagged)
        fprintf('  flagged rows: %s\n', mat2str(flagged'));
    end

    % ── Diagnostic figure per focus row ──────────────────────────────────
    for i = focusRows
        if i < 1 || i > nR || isempty(store{i})
            fprintf('  row %d: nothing to plot (%s)\n', i, char(R.err(min(max(i,1),nR))));
            continue;
        end
        local_plot(store{i}, R(i, :));
    end
end


% ── helpers ──────────────────────────────────────────────────────────────
function g = local_calib(func, fit, hasTrialFit, SLRT, i, x)
% Same branch order as postEXT_JOLT.
    if ~isempty(func)
        if hasTrialFit
            g = func(SLRT.calibFit_vonfrey(i, :), x);
        else
            g = func(fit, x);
        end
    else
        g = applyCalibrationFit(fit, x);
    end
end

function x = local_num(T, col, i)
    x = 0;
    if ismember(col, string(T.Properties.VariableNames))
        x = T.(col)(i);
        if iscell(x), x = x{1}; end
        x = double(x);
        if isempty(x) || ~isfinite(x), x = 0; end
    end
end

function y = local_numcol(c)
    if iscell(c)
        y = nan(numel(c), 1);
        for k = 1:numel(c)
            if isnumeric(c{k}) && isscalar(c{k}), y(k) = double(c{k}); end
        end
    else
        y = double(c(:));
    end
end

function s = local_first(tf)
    k = find(tf, 1);
    if isempty(k), s = '-'; else, s = num2str(k); end
end

function local_plot(S, r)
    t = S.t(:)';  cIn = [0.165 0.47 0.84];
    f = figure('Color', 'w', 'Position', [80 80 1300 520], ...
               'Name', sprintf('debugEXT_JOLT row %d', r.row));
    ax = axes(f); hold(ax, 'on');
    plot(ax, t, S.raw, 'Color', [0.8 0.8 0.8], 'DisplayName', 'stim raw');
    plot(ax, t, S.smooth, 'Color', cIn, 'LineWidth', 1.5, 'DisplayName', 'lowess 0.01');
    ev = {r.idxRtOnset, 'rt onset (t=0)', [0.4 0.4 0.4], ':';
          r.idxOnset, 'onset (auto)', [0.11 0.69 0.48], '-';
          r.idxOnset_advanced, 'onset + advance (used for thresh/delay)', [0.11 0.69 0.48], '--';
          r.idxOnsetAdvance_event, 'stimOnsetAdvance event (idx - advance)', [0.55 0.39 0.82], '--';
          r.idxPeak, 'peak = max tolerated force', [0.92 0.41 0.20], '-';
          r.idxPeak_delayed, 'peak + delay (withdrawal)', [0.92 0.41 0.20], '--'};
    for k = 1:size(ev, 1)
        idx = ev{k, 1};
        if isfinite(idx) && idx >= 1 && idx <= numel(t)
            xline(ax, t(idx), ev{k, 4}, 'Color', ev{k, 3}, 'LineWidth', 1.5, 'DisplayName', ev{k, 2});
        end
    end
    yline(ax, r.onsetVal, ':', 'Color', [0.11 0.69 0.48], 'HandleVisibility', 'off');
    yline(ax, r.maxVal, ':', 'Color', [0.92 0.41 0.20], 'HandleVisibility', 'off');
    flagNames = ["gate" "negRaw" "negGrams" "advSign"];
    flags = strjoin(flagNames(logical([r.gateMismatch r.negRaw r.negGrams r.advSign])), ', ');
    if flags == "", flags = "none"; end
    title(ax, sprintf(['row %d (trial %d, gate %d): rThresh = %.4g raw -> %.4g g, rDelay = %.3f s\n' ...
          'UI advance %.3f s, delay %.3f s | flags: %s'], ...
          r.row, r.trialNum0, r.trialGate, r.rThresh_raw, r.rThresh_g, r.rDelay_s, ...
          r.onsetAdvance_s, r.peakDelay_s, flags), 'Interpreter', 'none');
    xlabel(ax, 't (s, 0 = realtime onset)'); ylabel(ax, 'stim (raw sensor units)');
    legend(ax, 'Location', 'eastoutside', 'Box', 'off'); box(ax, 'off');
    if isfinite(r.idxOnset) && isfinite(r.idxPeak_delayed)
        pad = 0.5;
        xlim(ax, [t(max(1, r.idxOnset_advanced)) - pad, t(min(numel(t), r.idxPeak_delayed)) + pad]);
    end
end
