function [args_opt, fit_opt, diagnostics] = specParam_jointFit_legacy(f_psd, df_psd, args_init, doPlot, nCorners, logWeight)
% Joint lsqcurvefit over all aperiodic and periodic parameters simultaneously.
%
% The per-segment specparam workflow fits each frequency region independently,
% leaving the aperiodic baseline and periodic peaks mutually inconsistent.
% This function treats all parameters as simultaneously free and finds the
% single parameter set that best fits the full PSD in one shot.
%
% INPUTS
%   f_psd     : frequency axis, Hz (vector)
%   df_psd    : observed PSD in dB — 10·log10 power (same length as f_psd)
%   args_init : warm-start struct matching kernel_specparam_brokenPowerLaw
%               fields: OFF, EXP1..EXP_{N+1}, FC1..FC_N, CF_j, PW_j, BW_j
%               Typically: aperiodic fields from a prior aperiodic-only fit;
%               peak fields from per-segment specparam results.
%
% OUTPUTS
%   args_opt    : optimised parameter struct (same field layout as args_init)
%   fit_opt     : model evaluated at args_opt, dB (length of f_psd)
%   diagnostics : struct with resnorm, residuals, exitflag, output, jacobian
%
% PARAMETER VECTOR LAYOUT (internal, packed/unpacked automatically):
%   [OFF, EXP1..EXP_{N+1}, FC1..FC_N, CF1..CF_M, PW1..PW_M, BW1..BW_M]
%
% BOUNDS RATIONALE
%   OFF  : [0, 15]           log10 power offset; <0 unphysical, >15 extreme
%   EXP  : [0, 15]           spectral exponents; negative = rising spectrum,
%                            uncommon for neural LFP; >15 essentially a wall
%   FC   : [0.5·FC_init,     corners allowed ±50% of warm-start in log-space;
%           2.0·FC_init]     prevents them crossing or leaving the data range
%   CF   : [f_lo, f_hi]      peaks must stay within the fitted range
%   PW   : [0, 5]            peak height in log10 units; >5 (~31 dB) unrealistic
%   BW   : [0.5, range/3]    minimum half-Hz; at most a third of the full range

    if nargin < 4 || isempty(doPlot),    doPlot    = false; end
    if nargin < 5 || isempty(nCorners),  nCorners  = [];    end
    if nargin < 6 || isempty(logWeight), logWeight = true;  end

    f    = f_psd(:)';
    data = df_psd(:)';
    ax.f = f;

    % ── Discover structure from args_init ────────────────────────────────
    fNames   = fieldnames(args_init);
    fcNums   = extractFieldNums(fNames, '^FC\d+$',  2);
    expNums  = extractFieldNums(fNames, '^EXP\d+$', 3);
    peakNums = extractFieldNums(fNames, '^CF\d+$',  2);

    N    = numel(fcNums);    % corner frequencies  → N+1 segments
    M    = numel(peakNums);  % periodic peaks
    nEXP = numel(expNums);   % should equal N+1

    % ── Optionally collapse to fewer corners ─────────────────────────────
    % The segmented pipeline creates a corner at each segment boundary,
    % including artefactual ones.  nCorners lets you reduce the model to the
    % number of physiologically meaningful breaks (typically 1 for LFP).
    % EXP1 (low-freq slope) is preserved; the terminal high-freq slope from
    % the last segment is carried forward as EXP_{nCorners+1}.
    if ~isempty(nCorners) && nCorners < N
        args_init = trimCorners(args_init, fcNums, expNums, nCorners);
        fNames    = fieldnames(args_init);
        fcNums    = extractFieldNums(fNames, '^FC\d+$',  2);
        expNums   = extractFieldNums(fNames, '^EXP\d+$', 3);
        N         = numel(fcNums);
        nEXP      = numel(expNums);
    end

    % ── Anchor OFF warm-start to the data ────────────────────────────────
    % The segmented specparam OFF is per-segment and does not match the broken
    % power law convention (log10 power at f = 1 Hz, extrapolated by EXP1).
    % Re-derive from the first data point: model at f(1) ≈ 10*(OFF - EXP1*log10(f(1)))
    % when f(1) << FC1; solve for OFF.
    args_init.OFF = (data(1) + 10*args_init.EXP1*log10(max(f(1), 1e-10))) / 10;

    % ── Build initial parameter vector ───────────────────────────────────
    p0 = packParams(args_init, expNums, fcNums, peakNums);

    % ── Bounds ───────────────────────────────────────────────────────────
    f_lo = f(2);
    f_hi = f(end);

    % Aperiodic — symmetric additive margin around derived OFF so the bounds
    % are well-ordered even when OFF is negative or near zero.
    off_margin = max(abs(args_init.OFF) * 0.75, 3);
    lb_OFF = max(args_init.OFF - off_margin, -10);
    ub_OFF = min(args_init.OFF + off_margin,  50);
    % EXP: asymmetric bounds around each warm-start exponent.
    % EXP1 (low-freq) is expected to be small and should only be able to
    % decrease further — a large upper slack lets it drift toward the steep
    % high-freq slope, producing the degenerate equal-slope solution.
    % EXP_last (high-freq) is expected to be large and should only increase —
    % a large lower slack lets it collapse toward the low-freq slope.
    % Interior EXPs (if any) get a symmetric window.
    exp_init = arrayfun(@(k) args_init.(sprintf('EXP%d', k)), expNums(:)');
    lb_EXP   = zeros(1, nEXP);
    ub_EXP   = zeros(1, nEXP);
    for ki = 1:nEXP
        ei = exp_init(ki);
        if ki == 1          % low-freq: can decrease, barely increase
            lb_EXP(ki) = max(0,  ei - 1.5);
            ub_EXP(ki) = min(15, ei + 0.5);
        elseif ki == nEXP   % high-freq: can increase, barely decrease
            lb_EXP(ki) = max(0,  ei - 0.5);
            ub_EXP(ki) = min(15, ei + 1.5);
        else                % interior: symmetric
            lb_EXP(ki) = max(0,  ei - 1.0);
            ub_EXP(ki) = min(15, ei + 1.0);
        end
    end

    % Corner frequencies: ±25 % bracket around warm-start (same policy as CF).
    % The previous ±50 % window let FC drift a full octave, which allows the
    % optimizer to misplace the corner and compensate with peak power — the
    % corner should be identified primarily by the aperiodic model, not absorbed
    % into the periodic component.
    fc_init = cellfun(@(k) args_init.(sprintf('FC%d', k)), num2cell(fcNums(:)'));
    lb_FC   = max(f_lo,        fc_init * 0.75);
    ub_FC   = min(f_hi * 0.95, fc_init * 1.33);

    % Periodic: bracket each CF around its warm-start to prevent peaks from
    % drifting together.  ±25 % in linear frequency keeps each peak near its
    % specparam-identified centre while still allowing fine adjustment.
    if M > 0
        cf_init = cellfun(@(k) args_init.(sprintf('CF%d', k)), num2cell(peakNums(:)'));
        lb_CF = max(f_lo, cf_init * 0.75);
        ub_CF = min(f_hi, cf_init * 1.25);
    else
        lb_CF = zeros(1, 0);
        ub_CF = zeros(1, 0);
    end
    lb_PW = zeros(1, M);
    ub_PW = repmat(5, 1, M);

    % BW: bracket around warm-start to prevent the optimizer using a wide
    % Gaussian to absorb aperiodic corner features.  Hard cap at 8 Hz sigma
    % (≈ 19 Hz FWHM) — beyond this a "peak" is indistinguishable from a
    % slope change and belongs in the aperiodic model instead.
    if M > 0
        bw_init = cellfun(@(k) args_init.(sprintf('BW%d', k)), num2cell(peakNums(:)'));
        lb_BW = max(0.5,  bw_init * 0.5);
        ub_BW = min(8.0,  bw_init * 2.0);
    else
        lb_BW = zeros(1, 0);
        ub_BW = zeros(1, 0);
    end

    lb = [lb_OFF, lb_EXP, lb_FC, lb_CF, lb_PW, lb_BW];
    ub = [ub_OFF, ub_EXP, ub_FC, ub_CF, ub_PW, ub_BW];

    % ── Log-frequency resampling ──────────────────────────────────────────
    % A linearly-sampled PSD has far more HF than LF points, so the unweighted
    % objective is dominated by the HF region.  Explicit 1/f weighting fixes
    % the coverage but creates a 100–300× dynamic range in residual scale that
    % stalls trust-region step-size selection.  Resampling onto a log-spaced
    % grid achieves the same equal-octave coverage with no conditioning penalty
    % and fewer evaluations per iteration.
    if logWeight
        nLog     = min(200, numel(f));
        f_fit    = logspace(log10(max(f(2), f_lo)), log10(f_hi), nLog);
        data_fit = interp1(f, data, f_fit, 'linear');
    else
        f_fit    = f;
        data_fit = data;
    end
    fitModel = @(p, freq) evalBrokenPL(p, freq, expNums, fcNums, peakNums);

    % ── lsqcurvefit ──────────────────────────────────────────────────────
    lsqOpts = optimoptions('lsqcurvefit', ...
        'Algorithm',              'trust-region-reflective', ...
        'MaxFunctionEvaluations', 3000 * numel(p0), ...
        'MaxIterations',          1500, ...
        'FunctionTolerance',      1e-9, ...
        'StepTolerance',          1e-9, ...
        'Display',                'iter');

    [p_opt, resnorm, residuals, exitflag, output, ~, jacobian] = ...
        lsqcurvefit(fitModel, p0, f_fit, data_fit, lb, ub, lsqOpts);

    fprintf('[specParam_jointFit] exitflag=%d | resnorm=%.4f | iters=%d | fevals=%d\n', ...
        exitflag, resnorm, output.iterations, output.funcCount);

    if exitflag <= 0
        warning('specParam_jointFit: optimiser did not converge (exitflag=%d). Check warm-start quality and bounds.', exitflag);
    end

    % ── Unpack optimised parameters ───────────────────────────────────────
    args_opt = unpackParams(p_opt, args_init, expNums, fcNums, peakNums);

    % Ensure corner frequencies are in ascending order.
    % If the optimiser nudged FC_k past FC_{k+1}, reorder both the corners
    % and their bracketing EXP values so the segment assignment stays correct.
    args_opt = sortCorners(args_opt, fcNums, expNums);

    fit_opt = kernel_specparam_brokenPowerLaw(ax, args_opt);

    if doPlot
        % Aperiodic-only fit: zero out all periodic peaks.
        args_AP      = args_opt;
        for k = peakNums'
            args_AP.(sprintf('PW%d', k)) = 0;
        end
        fit_AP = kernel_specparam_brokenPowerLaw(ax, args_AP);

        figure;
        semilogx(f, data,    'Color', [0.6 0.6 0.6], 'LineWidth', 1,   'DisplayName', 'PSD');
        hold on;
        semilogx(f, fit_opt, 'r',                     'LineWidth', 1.5, 'DisplayName', 'Full fit');
        semilogx(f, fit_AP,  'b--',                   'LineWidth', 1.2, 'DisplayName', 'Aperiodic');

        % Corner frequency markers with EXP labels.
        yLims = ylim;
        for ki = 1:numel(fcNums)
            fc_val  = args_opt.(sprintf('FC%d',  fcNums(ki)));
            exp_lo  = args_opt.(sprintf('EXP%d', expNums(ki)));
            exp_hi  = args_opt.(sprintf('EXP%d', expNums(min(ki+1, numel(expNums)))));
            xline(fc_val, 'k:', 'LineWidth', 1.2, ...
                'Label',                  sprintf('FC%d=%.1f Hz\n%.2f→%.2f', fcNums(ki), fc_val, exp_lo, exp_hi), ...
                'LabelVerticalAlignment', 'middle', ...
                'LabelHorizontalAlignment', 'right');
        end

        xlabel('Frequency (Hz)'); ylabel('Power (dB)');
        title(sprintf('specParam joint fit  |  resnorm=%.1f  exitflag=%d  OFF=%.2f', ...
            resnorm, exitflag, args_opt.OFF));
        legend('Location', 'southwest'); grid on;
    end

    % ── Diagnostics ───────────────────────────────────────────────────────
    diagnostics.resnorm   = resnorm;
    diagnostics.residuals = residuals;
    diagnostics.exitflag  = exitflag;
    diagnostics.output    = output;
    diagnostics.jacobian  = jacobian;

    % Approximate parameter confidence intervals from the Jacobian.
    % ci(:,1) = lower bound, ci(:,2) = upper bound at 95% confidence.
    try
        ci = nlparci(p_opt, residuals, 'jacobian', full(jacobian));
        diagnostics.ci     = ci;
        diagnostics.ci_pNames = paramNames(expNums, fcNums, peakNums);
    catch
        diagnostics.ci = [];
    end
end


% ═══════════════════════════════════════════════════════════════════════════
% LOCAL HELPERS
% ═══════════════════════════════════════════════════════════════════════════

function fit = evalBrokenPL(p, f, expNums, fcNums, peakNums)
% Unpack parameter vector → args struct → kernel.  Called at every iteration.
    ax_loc.f = f(:)';
    args = unpackParams(p, struct(), expNums, fcNums, peakNums);
    fit  = kernel_specparam_brokenPowerLaw(ax_loc, args);
end


function p = packParams(args, expNums, fcNums, peakNums)
% Flatten args struct into the parameter vector [OFF, EXPs, FCs, CFs, PWs, BWs].
    p = args.OFF;
    for k = expNums',  p = [p, args.(sprintf('EXP%d', k))]; end
    for k = fcNums',   p = [p, args.(sprintf('FC%d',  k))]; end
    for k = peakNums', p = [p, args.(sprintf('CF%d',  k))]; end
    for k = peakNums', p = [p, args.(sprintf('PW%d',  k))]; end
    for k = peakNums', p = [p, args.(sprintf('BW%d',  k))]; end
end


function args = unpackParams(p, args_template, expNums, fcNums, peakNums)
% Reconstruct args struct from parameter vector.
% args_template is used to preserve any non-optimised fields.
    args     = args_template;
    nEXP     = numel(expNums);
    N        = numel(fcNums);
    M        = numel(peakNums);

    cursor = 1;
    args.OFF = p(cursor); cursor = cursor + 1;

    for ki = 1:nEXP
        args.(sprintf('EXP%d', expNums(ki))) = p(cursor); cursor = cursor + 1;
    end
    for ki = 1:N
        args.(sprintf('FC%d', fcNums(ki))) = p(cursor); cursor = cursor + 1;
    end
    for ki = 1:M
        args.(sprintf('CF%d', peakNums(ki))) = p(cursor); cursor = cursor + 1;
    end
    for ki = 1:M
        args.(sprintf('PW%d', peakNums(ki))) = p(cursor); cursor = cursor + 1;
    end
    for ki = 1:M
        args.(sprintf('BW%d', peakNums(ki))) = p(cursor); cursor = cursor + 1;
    end
end


function args = sortCorners(args, fcNums, expNums)
% If the optimiser moved any FC past a neighbour, sort them back into
% ascending order and permute EXP values to match.
%
% Each FC_k is paired with EXP_{k+1}: the slope that applies above that
% corner.  When corners reorder, EXP2..EXP_{N+1} reorder by the same
% permutation.  EXP1 (the below-all-corners slope) is left untouched.
    if numel(fcNums) < 2, return; end

    fc_vals = arrayfun(@(k) args.(sprintf('FC%d', k)), fcNums);
    [fc_sorted, ord] = sort(fc_vals);

    if isequal(ord, 1:numel(fcNums)), return; end  % already sorted

    for ki = 1:numel(fcNums)
        args.(sprintf('FC%d', fcNums(ki))) = fc_sorted(ki);
    end

    % Reorder paired EXPs only when the struct is fully specified (nEXP = N+1).
    % Under-specified structs (nEXP <= N) keep their EXP values as-is.
    if numel(expNums) < numel(fcNums) + 1, return; end

    paired = expNums(2:end);   % EXP2..EXP_{N+1}, exactly N entries
    exp_vals = arrayfun(@(k) args.(sprintf('EXP%d', k)), paired);
    exp_sorted = exp_vals(ord);
    for ki = 1:numel(paired)
        args.(sprintf('EXP%d', paired(ki))) = exp_sorted(ki);
    end
end


function args = trimCorners(args, fcNums, expNums, nCorners)
% Reduce a multi-corner warm-start to nCorners corner frequencies.
%
% For nCorners == 1 the corner is chosen by largest slope change |EXP_k - EXP_{k+1}|.
% EXP1 (low-freq slope) is kept as-is.  EXP2 is taken from expNums(bestIdx) —
% the EXP paired with the selected corner — NOT expNums(end).
%
% The reason: in a Lorentzian warm-start the last EXP (expNums(end)) is often
% near zero because the final Lorentzian factor contributes little rolloff,
% while the EXP that drove the slope-change selection (expNums(bestIdx)) is
% the one that best represents the steep high-frequency decay the broken
% power law's EXP2 should capture.
%
% For nCorners > 1 the first nCorners FCs are kept (original order).
    N    = numel(fcNums);
    nExp = numel(expNums);

    if nCorners == 1
        % Score each corner by its slope change magnitude.
        nPairs = min(N, nExp - 1);
        delta  = zeros(1, N);
        for ki = 1:nPairs
            e1 = args.(sprintf('EXP%d', expNums(ki)));
            e2 = args.(sprintf('EXP%d', expNums(ki+1)));
            delta(ki) = abs(e1 - e2);
        end
        [~, bestIdx] = max(delta);
        bestFC = args.(sprintf('FC%d', fcNums(bestIdx)));

        % termSlope: EXP at the selected corner position, which is the Lorentzian
        % factor that produced the dominant slope change and best approximates the
        % broken power law's high-frequency segment slope.
        termSlope = args.(sprintf('EXP%d', expNums(min(bestIdx, nExp))));

        % Rebuild: EXP1 (kept), FC1 = best corner, EXP2 = termSlope.
        for k = fcNums'
            args = rmfield(args, sprintf('FC%d', k));
        end
        for k = expNums(2:end)'
            args = rmfield(args, sprintf('EXP%d', k));
        end
        args.FC1  = bestFC;
        args.EXP2 = termSlope;

    else
        % Keep first nCorners FCs and carry terminal slope to position nCorners+1.
        for k = fcNums(nCorners+1:end)'
            args = rmfield(args, sprintf('FC%d', k));
        end
        % For the general case, termSlope = the EXP that follows the last kept corner.
        termSlope = args.(sprintf('EXP%d', expNums(min(nCorners+1, nExp))));
        args.(sprintf('EXP%d', expNums(nCorners+1))) = termSlope;
        if nExp > nCorners + 1
            for k = expNums(nCorners+2:end)'
                args = rmfield(args, sprintf('EXP%d', k));
            end
        end
    end
end


function nums = extractFieldNums(fNames, pattern, stripLen)
% Return sorted numeric suffixes for fields matching pattern.
% stripLen: number of leading characters to strip before parsing the number.
    matched = fNames(~cellfun(@isempty, regexp(fNames, pattern, 'match')));
    nums    = sort(cellfun(@(s) str2double(s(stripLen+1:end)), matched));
    nums    = nums(~isnan(nums));
end


function names = paramNames(expNums, fcNums, peakNums)
% Human-readable parameter names in pack order (for CI table annotation).
    names = ['OFF', ...
             arrayfun(@(k) sprintf('EXP%d', k), expNums,  'UniformOutput', false), ...
             arrayfun(@(k) sprintf('FC%d',  k), fcNums,   'UniformOutput', false), ...
             arrayfun(@(k) sprintf('CF%d',  k), peakNums, 'UniformOutput', false), ...
             arrayfun(@(k) sprintf('PW%d',  k), peakNums, 'UniformOutput', false), ...
             arrayfun(@(k) sprintf('BW%d',  k), peakNums, 'UniformOutput', false)];
end
