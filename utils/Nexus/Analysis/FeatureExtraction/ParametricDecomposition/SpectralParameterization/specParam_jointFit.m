function [args_opt, fit_opt, diagnostics] = specParam_jointFit(f_psd, df_psd, args_init, doPlot, nCorners, logWeight)
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

    f_lo = f(2);
    f_hi = f(end);

    % ── Log-frequency resampling (shared by both phases) ──────────────────
    % Equal-octave coverage without the 100–300× residual dynamic range that
    % explicit 1/f weighting causes.
    if logWeight
        nLog     = min(200, numel(f));
        f_fit    = logspace(log10(max(f(2), f_lo)), log10(f_hi), nLog);
        data_fit = interp1(f, data, f_fit, 'linear');
    else
        f_fit    = f;
        data_fit = data;
    end

    if doPlot, args_preP1 = args_init; end   % snapshot warm-start before Phase 1 modifies it

    % ── Phase 1: Aperiodic pre-fit on peak-masked data ────────────────────
    % Peak amplitude and aperiodic slope trade off in joint optimization —
    % the optimizer absorbs peak power into the EXP values, producing
    % degenerate equal-slope solutions.  Masking ±2·BW around each warm-start
    % CF removes this confound: the aperiodic model fitted alone on the masked
    % grid gives identifiable EXP/FC/OFF that Phase 2 can anchor to.
    mask_ap = true(size(f_fit));
    for k = peakNums'
        cf_k = args_init.(sprintf('CF%d', k));
        bw_k = args_init.(sprintf('BW%d', k));
        mask_ap = mask_ap & (abs(f_fit - cf_k) > 2 * bw_k);
    end
    if sum(mask_ap) >= 2 * (nEXP + N)
        f_ap    = f_fit(mask_ap);
        data_ap = data_fit(mask_ap);
    else
        warning('specParam_jointFit: peak masking left too few points (%d) for Phase 1 pre-fit. Using all log-resampled points.', sum(mask_ap));
        f_ap    = f_fit;
        data_ap = data_fit;
    end

    p0_ap = packParams(args_init, expNums, fcNums, []);
    fitAP = @(p, freq) evalBrokenPL(p, freq, expNums, fcNums, []);

    % Wide bounds for Phase 1 — EXPs free to find any physiological value;
    % FC allowed full data range so corners aren't forced by the warm-start.
    lb_ap = [max(args_init.OFF - 10, -10), zeros(1, nEXP),    repmat(f_lo,        1, N)];
    ub_ap = [min(args_init.OFF + 20,  50), repmat(15, 1, nEXP), repmat(f_hi * 0.95, 1, N)];

    lsqOpts_AP = optimoptions('lsqcurvefit', ...
        'Algorithm',              'trust-region-reflective', ...
        'MaxFunctionEvaluations', 1000 * numel(p0_ap), ...
        'MaxIterations',          500, ...
        'FunctionTolerance',      1e-8, ...
        'StepTolerance',          1e-8, ...
        'Display',                'off');

    [p_ap, resnorm_ap, ~, exitflag_ap] = ...
        lsqcurvefit(fitAP, p0_ap, f_ap, data_ap, lb_ap, ub_ap, lsqOpts_AP);

    fprintf('[specParam_jointFit] Phase 1 (aperiodic pre-fit): exitflag=%d | resnorm=%.4f\n', ...
        exitflag_ap, resnorm_ap);

    % Unpack Phase 1 result: update aperiodic fields in args_init for Phase 2
    args_ap = unpackParams(p_ap, args_init, expNums, fcNums, []);
    args_init.OFF = args_ap.OFF;
    for k = expNums'
        args_init.(sprintf('EXP%d', k)) = args_ap.(sprintf('EXP%d', k));
    end
    for k = fcNums'
        args_init.(sprintf('FC%d', k)) = args_ap.(sprintf('FC%d', k));
    end

    if doPlot
        p_preP1      = packParams(args_preP1, expNums, fcNums, []);
        fit_AP_preP1 = evalBrokenPL(p_preP1, f, expNums, fcNums, []);
        fit_AP_postP1 = evalBrokenPL(p_ap,   f, expNums, fcNums, []);

        figure;
        semilogx(f, data, 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'DisplayName', 'PSD');
        hold on;
        % Mark which log-resampled points were masked (peak regions)
        semilogx(f_fit(~mask_ap), data_fit(~mask_ap), 'rx', 'MarkerSize', 5, ...
            'HandleVisibility', 'off');
        semilogx(f_fit(mask_ap),  data_fit(mask_ap),  'b.', 'MarkerSize', 3, ...
            'HandleVisibility', 'off');
        semilogx(f, fit_AP_preP1,  'b--', 'LineWidth', 1.2, 'DisplayName', 'Pre  (warm-start aperiodic)');
        semilogx(f, fit_AP_postP1, 'b',   'LineWidth', 1.5, 'DisplayName', 'Post (Phase 1 aperiodic)');
        xlabel('Frequency (Hz)'); ylabel('Power (dB)');
        title(sprintf('Phase 1: Aperiodic pre-fit  |  resnorm=%.2f  exitflag=%d', ...
            resnorm_ap, exitflag_ap));
        legend('Location', 'southwest'); grid on;
        % annotation: red × = masked (peak region), blue · = used in fit
        text(0.02, 0.05, '{\color{red}\times} masked   {\color{blue}.} used', ...
            'Units', 'normalized', 'FontSize', 8);
    end

    % ── Phase 2: Peak-only fit against Phase 1 aperiodic baseline ─────────
    % Subtract Phase 1 aperiodic from data; fit Gaussian peaks to the residual
    % alone.  With only 3·M free parameters and no aperiodic cross-terms this
    % is a simple deconvolution — it converges reliably and gives Phase 3 a
    % good peak warm-start so the joint step only needs fine adjustment.
    if M > 0
        fit_AP1  = evalBrokenPL(p_ap, f_fit, expNums, fcNums, []);
        resid_ap = data_fit - fit_AP1;

        cf_init = cellfun(@(k) args_init.(sprintf('CF%d', k)), num2cell(peakNums(:)'));
        pw_init = cellfun(@(k) args_init.(sprintf('PW%d', k)), num2cell(peakNums(:)'));
        bw_init = cellfun(@(k) args_init.(sprintf('BW%d', k)), num2cell(peakNums(:)'));
        p0_pk   = [cf_init, pw_init, bw_init];

        lb_pk = [max(f_lo, cf_init * 0.75), zeros(1, M),     max(0.5, bw_init * 0.5)];
        ub_pk = [min(f_hi, cf_init * 1.25), repmat(5, 1, M), min(8.0, bw_init * 2.0)];

        fitPeaks = @(p_pk, freq) evalGaussianPeaks(p_pk, freq, M);

        lsqOpts_PK = optimoptions('lsqcurvefit', ...
            'Algorithm',              'trust-region-reflective', ...
            'MaxFunctionEvaluations', 500 * numel(p0_pk), ...
            'MaxIterations',          300, ...
            'FunctionTolerance',      1e-8, ...
            'StepTolerance',          1e-8, ...
            'Display',                'off');

        [p_pk, resnorm_pk, ~, exitflag_pk] = ...
            lsqcurvefit(fitPeaks, p0_pk, f_fit, resid_ap, lb_pk, ub_pk, lsqOpts_PK);

        fprintf('[specParam_jointFit] Phase 2 (peak pre-fit):    exitflag=%d | resnorm=%.4f\n', ...
            exitflag_pk, resnorm_pk);

        % Update peak fields in args_init for Phase 3 warm-start
        for ki = 1:M
            args_init.(sprintf('CF%d', peakNums(ki))) = p_pk(ki);
            args_init.(sprintf('PW%d', peakNums(ki))) = p_pk(M  + ki);
            args_init.(sprintf('BW%d', peakNums(ki))) = p_pk(2*M + ki);
        end

        if doPlot
            % Phase 1 aperiodic on original f (fixed baseline for both pre/post)
            ap1_on_f   = evalBrokenPL(p_ap, f, expNums, fcNums, []);
            resid_on_f = data - ap1_on_f;

            % Pre-Phase 2: warm-start peak positions (cf_init / pw_init / bw_init)
            peak_preP2 = zeros(size(f));
            for ki = 1:M
                peak_preP2 = peak_preP2 + ...
                    10 * pw_init(ki) * exp(-(f - cf_init(ki)).^2 / (2 * bw_init(ki)^2));
            end

            % Post-Phase 2: Phase 2 fitted peaks
            peak_postP2 = evalGaussianPeaks(p_pk, f, M);

            figure;
            semilogx(f, resid_on_f,  'Color', [0.7 0.7 0.7], 'LineWidth', 1,   'DisplayName', 'Residual (data − AP1)');
            hold on;
            semilogx(f, peak_preP2,  'r--',                   'LineWidth', 1.2, 'DisplayName', 'Pre  (warm-start peaks)');
            semilogx(f, peak_postP2, 'r',                     'LineWidth', 1.5, 'DisplayName', 'Post (Phase 2 peaks)');
            yline(0, 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
            xlabel('Frequency (Hz)'); ylabel('Power above aperiodic (dB)');
            title(sprintf('Phase 2: Peak pre-fit  |  resnorm=%.2f  exitflag=%d', ...
                resnorm_pk, exitflag_pk));
            legend('Location', 'northeast'); grid on;
        end
    end

    % ── Phase 3: Joint refinement with tight bounds from Phases 1–2 ───────
    % All parameters start from data-driven values.  Tight aperiodic bounds
    % prevent the optimizer from revisiting the EXP–peak trade-off; peak
    % bounds are bracketed around Phase 2 positions so they only fine-tune.
    p0 = packParams(args_init, expNums, fcNums, peakNums);

    % OFF: tight margin around Phase 1 result
    off_margin = max(abs(args_init.OFF) * 0.25, 1.5);
    lb_OFF = max(args_init.OFF - off_margin, -10);
    ub_OFF = min(args_init.OFF + off_margin,  50);

    % EXP: tight ±0.5 around Phase 1 values (well-identified from masked pre-fit)
    exp_init = arrayfun(@(k) args_init.(sprintf('EXP%d', k)), expNums(:)');
    lb_EXP   = max(0,  exp_init - 0.5);
    ub_EXP   = min(15, exp_init + 0.5);

    % FC: ±25% around Phase 1 values
    fc_init = cellfun(@(k) args_init.(sprintf('FC%d', k)), num2cell(fcNums(:)'));
    lb_FC   = max(f_lo,        fc_init * 0.75);
    ub_FC   = min(f_hi * 0.95, fc_init * 1.33);

    % Peaks: bracketed around Phase 2 positions
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

    fitModel = @(p, freq) evalBrokenPL(p, freq, expNums, fcNums, peakNums);

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
        % Pre-Phase 3: Phase 1 aperiodic + Phase 2 peaks (args_init at this point)
        fit_preP3 = kernel_specparam_brokenPowerLaw(ax, args_init);

        % Post-Phase 3: final result and its aperiodic-only component
        args_AP = args_opt;
        for k = peakNums'
            args_AP.(sprintf('PW%d', k)) = 0;
        end
        fit_AP_postP3 = kernel_specparam_brokenPowerLaw(ax, args_AP);

        figure;
        semilogx(f, data,         'Color', [0.6 0.6 0.6], 'LineWidth', 1,   'DisplayName', 'PSD');
        hold on;
        semilogx(f, fit_preP3,    'm--',                   'LineWidth', 1.2, 'DisplayName', 'Pre  (Phase 1+2)');
        semilogx(f, fit_opt,      'r',                     'LineWidth', 1.5, 'DisplayName', 'Post (Phase 3 joint)');
        semilogx(f, fit_AP_postP3,'b--',                   'LineWidth', 1.2, 'DisplayName', 'Aperiodic (Phase 3)');

        for ki = 1:numel(fcNums)
            fc_val  = args_opt.(sprintf('FC%d',  fcNums(ki)));
            exp_lo  = args_opt.(sprintf('EXP%d', expNums(ki)));
            exp_hi  = args_opt.(sprintf('EXP%d', expNums(min(ki+1, numel(expNums)))));
            xline(fc_val, 'k:', 'LineWidth', 1.2, ...
                'Label',                    sprintf('FC%d=%.1f Hz\n%.2f→%.2f', fcNums(ki), fc_val, exp_lo, exp_hi), ...
                'LabelVerticalAlignment',   'middle', ...
                'LabelHorizontalAlignment', 'right');
        end

        xlabel('Frequency (Hz)'); ylabel('Power (dB)');
        title(sprintf('Phase 3: Joint refinement  |  resnorm=%.1f  exitflag=%d  OFF=%.2f', ...
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


function fit = evalGaussianPeaks(p_pk, f, M)
% Sum of M Gaussian peaks in dB.  Parameter vector: [CF1..M, PW1..M, BW1..M].
% Matches the 10·PW·gaussian convention used by kernel_specparam_brokenPowerLaw.
    f   = f(:)';
    fit = zeros(1, numel(f));
    for ki = 1:M
        CF  = p_pk(ki);
        PW  = p_pk(M  + ki);
        BW  = p_pk(2*M + ki);
        fit = fit + 10 * PW * exp(-(f - CF).^2 / (2 * BW^2));
    end
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
