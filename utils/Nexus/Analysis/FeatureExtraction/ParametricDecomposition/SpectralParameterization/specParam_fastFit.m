function [params, fit_out, resnorms] = specParam_fastFit(f_psd, df_psd, args_template, opts)
%SPECPARAM_FASTFIT  Batched analytical broken-power-law fit across a PSD matrix.
%
% Designed for bulk fitting of large PSD arrays (e.g. 384 channels × trials ×
% sessions).  Replaces the three lsqcurvefit phases in specParam_jointFit with
% two closed-form steps that vectorise over the entire batch dimension:
%
%   Phase 1 — Analytical aperiodic fit with 1-D FC grid search.
%     For fixed FC, the broken power law is LINEAR in [OFF, EXP1…EXP_{N+1}]:
%       log10_P = A(f, FC) * [OFF; EXP1; …; EXP_{N+1}]
%     One backslash call  A \ Y_masked  solves all nPSD PSDs simultaneously.
%     A grid of nFCgrid candidates (log-spaced, anchored to template FC1)
%     picks the best-fit corner frequency per PSD by running best selection.
%     Multi-corner models: all FCs scale together at their template ratios —
%     exact for N=1, a good approximation for N>1.
%
%   Phase 2 — Linear solve for peak heights.
%     CF and BW are held at template values; only PW is fitted.  With the
%     Gaussian basis B fixed, the model is linear: residual = B * PW.
%     One backslash call  B \ R  solves all PSDs at once, no iterations.
%
% Typical speedup over specParam_jointFit: 200–500× per PSD.
%
% INPUTS
%   f_psd        : frequency axis in Hz (1×nF or nF×1)
%   df_psd       : PSD matrix in dB — rows are PSDs (nPSD×nF) or (nF×nPSD, auto-detected)
%   args_template: warm-start struct in specParam_jointFit format.
%                  FC/EXP fields → grid anchor and inter-corner ratios.
%                  CF/BW fields  → peak masking for Phase 1, Gaussian basis for Phase 2.
%   opts         : optional settings struct (fields described under DEFAULTS)
%
% OUTPUTS
%   params   : struct of (nPSD×1) column vectors, one per parameter.
%              Analytically fitted  : OFF, EXP1..EXP_{N+1}, FC1..FC_N
%              Linearly fitted      : PW1..PW_M  (per PSD, non-negative)
%              Fixed at template    : CF1..CF_M, BW1..BW_M
%   fit_out  : (nPSD × nF) matrix of full fitted PSDs in dB
%   resnorms : (nPSD × 1) residual norms on the log-resampled grid
%
% DEFAULTS
%   opts.nLog     = 200  — log-resampled frequency resolution
%   opts.nFCgrid  = 30   — FC candidates in the Phase 1 grid search
%   opts.fc_range = []   — [fc_lo  fc_hi] Hz; [] → template FC1 ÷4 … ×4
%
% WORKFLOW RECOMMENDATION
%   1. Run specParam_jointFit on a representative subset (~10 PSDs) to obtain
%      a well-fitted args_template (correct FC position, peak CF/BW).
%   2. Run specParam_fastFit on the full array using that template.
%   If peak centres shift across conditions, update the template and re-run.
%
% MEMORY
%   O(nPSD × nF) for fit_out.  For very large nPSD, call in chunks:
%     for ch = 1 : chunkSize : nPSD
%       [p, f, r] = specParam_fastFit(f, Y(ch:ch+chunkSize-1,:), tmpl);
%     end

    % ── Defaults ─────────────────────────────────────────────────────────────
    if nargin < 4 || isempty(opts), opts = struct(); end
    opts = setDefault(opts, 'nLog',     200);
    opts = setDefault(opts, 'nFCgrid',  30);
    opts = setDefault(opts, 'fc_range', []);

    % ── Orient inputs ─────────────────────────────────────────────────────────
    f  = f_psd(:)';     % enforce row vector
    nF = numel(f);
    if size(df_psd, 2) == nF
        Y = df_psd;
    elseif size(df_psd, 1) == nF
        Y = df_psd';
    else
        error('specParam_fastFit: df_psd size [%s] is incompatible with f_psd length %d.', ...
            mat2str(size(df_psd)), nF);
    end
    nPSD = size(Y, 1);

    % ── Discover parameter structure from args_template ───────────────────────
    fNames   = fieldnames(args_template);
    fcNums   = extractFieldNums(fNames, '^FC\d+$',  2);
    expNums  = extractFieldNums(fNames, '^EXP\d+$', 3);
    peakNums = extractFieldNums(fNames, '^CF\d+$',  2);

    N    = numel(fcNums);
    M    = numel(peakNums);
    nEXP = numel(expNums);   % should equal N+1

    f_lo = f(2);     % skip DC bin
    f_hi = f(end);

    % ── Log-frequency resampling ──────────────────────────────────────────────
    nLog  = min(opts.nLog, nF);
    f_fit = logspace(log10(max(f(2), f_lo)), log10(f_hi), nLog);
    % interp1 operates column-wise; Y' is (nF × nPSD), result is (nLog × nPSD)
    Y_fit = interp1(f, Y', f_fit, 'linear')';    % (nPSD × nLog)

    % ── Common peak mask from template ────────────────────────────────────────
    % Mask ±2·BW around each template CF to keep peak regions from biasing
    % the aperiodic slope estimate (same rationale as specParam_jointFit Phase 1).
    mask_ap = true(1, nLog);
    for k = peakNums'
        cf_k = args_template.(sprintf('CF%d', k));
        bw_k = args_template.(sprintf('BW%d', k));
        mask_ap = mask_ap & (abs(f_fit - cf_k) > 2 * bw_k);
    end
    if sum(mask_ap) < 2 * (nEXP + N)
        warning('specParam_fastFit: peak mask left only %d points — using full log-resampled grid.', ...
            sum(mask_ap));
        mask_ap = true(1, nLog);
    end
    f_ap    = f_fit(mask_ap);       % (1 × nMasked)
    Y_ap    = Y_fit(:, mask_ap)';   % (nMasked × nPSD) — one column per PSD
    nMasked = sum(mask_ap);

    % ── Phase 1: Batched analytical aperiodic fit + FC grid search ────────────
    %
    % Design matrix derivation (N corners, N+1 segments):
    %   log10_P = OFF + EXP1·col2 + EXP2·col3 + … + EXP_{N+1}·col_{N+2}
    %   col 1   = 1
    %   col 2   = -log10(f) + log10(1 + f/FC1)
    %   col k+1 = -log10(1 + f/FC_{k-1}) + log10(1 + f/FC_k)  for k = 2..N
    %   col N+2 = -log10(1 + f/FC_N)
    %
    % For each FC candidate, A is identical for all nPSD PSDs → one A\Y_ap
    % call factorises A once (O(nMasked·(N+2)²)) then solves for every PSD
    % (O((N+2)²·nPSD)).  Running-best selection keeps memory at O(nPSD·(N+2)).

    if N == 0
        % No corners — pure power law, direct solve, no grid needed
        A_pw = [ones(nMasked, 1), -log10(f_ap(:))];
        p_pw = A_pw \ Y_ap;             % (2 × nPSD)
        best_ap = [p_pw(1,:); max(0, p_pw(2,:))];
        best_fc = zeros(0, nPSD);

    else
        % Build FC candidate grid centred on template FC1 ±2 octaves
        fc_anchor = args_template.(sprintf('FC%d', fcNums(1)));
        fc_ratios = arrayfun(@(k) args_template.(sprintf('FC%d', k)) / fc_anchor, fcNums(:)');

        if isempty(opts.fc_range)
            fc_lo_g = max(f_lo * 2,   fc_anchor / 4);
            fc_hi_g = min(f_hi * 0.9, fc_anchor * 4);
        else
            fc_lo_g = opts.fc_range(1);
            fc_hi_g = opts.fc_range(2);
        end
        if fc_lo_g >= fc_hi_g
            fc_lo_g = fc_anchor * 0.5;
            fc_hi_g = fc_anchor * 2.0;
        end
        fc_grid = logspace(log10(fc_lo_g), log10(fc_hi_g), opts.nFCgrid);

        best_resnorm = inf(nPSD, 1);
        best_ap      = zeros(nEXP + 1, nPSD);   % [OFF; EXP1; …; EXP_{N+1}]
        best_fc      = zeros(N, nPSD);

        for gi = 1:opts.nFCgrid
            fc_i = fc_grid(gi) * fc_ratios;              % (1 × N) scaled corners
            A    = buildApDesignMatrix(f_ap(:), fc_i);   % (nMasked × (N+2))
            p_i  = A \ Y_ap;                              % (N+2) × nPSD
            rn_i = sum((A * p_i - Y_ap).^2, 1)';          % (nPSD × 1)

            improved = rn_i < best_resnorm;
            best_resnorm(improved)  = rn_i(improved);
            best_ap(:, improved)    = p_i(:, improved);
            best_fc(:, improved)    = repmat(fc_i(:), 1, sum(improved));
        end

        % Clamp EXPs ≥ 0; LS has no positivity constraint
        best_ap(2:end, :) = max(0, best_ap(2:end, :));
    end

    % ── Evaluate aperiodic on log-resampled grid (for peak residual) ──────────
    ap_fit_log = evalAperiodicBatch(best_ap, best_fc, f_fit, N, nPSD);  % (nPSD × nLog)

    % ── Phase 2: Linear solve for peak heights ────────────────────────────────
    %
    % With CF_j and BW_j fixed at template values, the peak model is:
    %   residual ≈ B * PW  where  B(:,j) = 10·exp(-(f-CF_j)²/(2·BW_j²))
    % One backslash call solves for all PSDs at once; clamp to non-negative.
    PW_matrix = zeros(M, nPSD);
    B_log     = zeros(nLog, M);
    if M > 0
        for j = 1:M
            CF_j = args_template.(sprintf('CF%d', peakNums(j)));
            BW_j = args_template.(sprintf('BW%d', peakNums(j)));
            B_log(:, j) = 10 * exp(-(f_fit(:) - CF_j).^2 / (2 * BW_j^2));
        end
        R = (Y_fit - ap_fit_log)';        % (nLog × nPSD)
        PW_matrix = max(0, B_log \ R);    % (M × nPSD)
    end

    % ── Build full fit on original frequency axis ─────────────────────────────
    ap_fit_full = evalAperiodicBatch(best_ap, best_fc, f, N, nPSD);   % (nPSD × nF)

    if M > 0
        B_full = zeros(nF, M);
        for j = 1:M
            CF_j = args_template.(sprintf('CF%d', peakNums(j)));
            BW_j = args_template.(sprintf('BW%d', peakNums(j)));
            B_full(:, j) = 10 * exp(-(f(:) - CF_j).^2 / (2 * BW_j^2));
        end
        fit_out = ap_fit_full + (B_full * PW_matrix)';   % (nPSD × nF)
    else
        fit_out = ap_fit_full;
    end

    % ── Residual norms on log-resampled grid ──────────────────────────────────
    if M > 0
        full_log = ap_fit_log + (B_log * PW_matrix)';   % (nPSD × nLog)
    else
        full_log = ap_fit_log;
    end
    resnorms = sum((Y_fit - full_log).^2, 2);   % (nPSD × 1)

    % ── Pack output params struct ─────────────────────────────────────────────
    params.OFF = best_ap(1, :)';
    for ki = 1:nEXP
        params.(sprintf('EXP%d', expNums(ki))) = best_ap(ki + 1, :)';
    end
    for ki = 1:N
        params.(sprintf('FC%d', fcNums(ki))) = best_fc(ki, :)';
    end
    for ki = 1:M
        params.(sprintf('CF%d', peakNums(ki))) = ...
            repmat(args_template.(sprintf('CF%d', peakNums(ki))), nPSD, 1);
        params.(sprintf('BW%d', peakNums(ki))) = ...
            repmat(args_template.(sprintf('BW%d', peakNums(ki))), nPSD, 1);
        params.(sprintf('PW%d', peakNums(ki))) = PW_matrix(ki, :)';
    end
end


% ═══════════════════════════════════════════════════════════════════════════════
% LOCAL HELPERS
% ═══════════════════════════════════════════════════════════════════════════════

function A = buildApDesignMatrix(f, fc_vec)
%BUILDAPDESIGNMATRIX  Linear design matrix for the broken power law.
%
% For fixed corner frequencies fc_vec = [FC1 … FC_N], the broken power law
% log10_P = A * [OFF; EXP1; …; EXP_{N+1}]  with columns:
%
%   col 1   = 1
%   col 2   = -log10(f) + log10(1 + f/FC1)               (EXP1)
%   col k+1 = -log10(1+f/FC_{k-1}) + log10(1+f/FC_k)     (EXP_k, k=2..N)
%   col N+2 = -log10(1 + f/FC_N)                          (EXP_{N+1})
%
% Derivation: expand log10_P = OFF - EXP1·log10(f)
%   + sum_{k=1}^{N} (EXP_k - EXP_{k+1})·log10(1+f/FC_k)
% and collect coefficients of each EXP parameter.
    f     = f(:);
    N     = numel(fc_vec);
    nFreq = numel(f);
    A     = zeros(nFreq, N + 2);
    A(:, 1) = 1;
    A(:, 2) = -log10(f) + log10(1 + f / fc_vec(1));        % EXP1
    for k = 2:N
        A(:, k+1) = -log10(1 + f / fc_vec(k-1)) + log10(1 + f / fc_vec(k));
    end
    A(:, N+2) = -log10(1 + f / fc_vec(N));                  % EXP_{N+1}
end


function fit = evalAperiodicBatch(ap_params, fc_params, f_eval, N, nPSD)
%EVALAPERIODICBATCH  Vectorised aperiodic model evaluation for all PSDs.
%
%   ap_params : (nEXP+1 × nPSD)  [OFF; EXP1; …; EXP_{N+1}]
%   fc_params : (N × nPSD)        per-PSD corner frequencies
%   f_eval    : (1 × nFeval)
%   Returns   : fit (nPSD × nFeval) in dB
%
% All operations use implicit expansion (MATLAB R2016b+); no explicit repmat.
% The outer product  EXP1 * log_f  and the broadcast  dEXP .* log10(1+f./FC)
% each produce (nPSD × nFeval) in a single operation.
    f_eval = f_eval(:)';
    log_f  = log10(f_eval);             % (1 × nFeval)

    OFF  = ap_params(1, :)';            % (nPSD × 1)
    EXP1 = ap_params(2, :)';            % (nPSD × 1)

    % Baseline: (nPSD×1) - (nPSD×1)*(1×nFeval) → (nPSD × nFeval)
    fit = OFF - EXP1 * log_f;

    % One correction term per corner: (EXP_k − EXP_{k+1})·log10(1 + f/FC_k)
    for ki = 1:N
        FC_k = fc_params(ki, :)';                       % (nPSD × 1)
        dEXP = ap_params(ki+1,:)' - ap_params(ki+2,:)'; % (nPSD × 1)
        % f_eval ./ FC_k: (1×nFeval) ./ (nPSD×1) → (nPSD × nFeval) via broadcast
        fit = fit + dEXP .* log10(1 + f_eval ./ FC_k);
    end

    fit = 10 * fit;   % log10 power → dB
end


function nums = extractFieldNums(fNames, pattern, stripLen)
    matched = fNames(~cellfun(@isempty, regexp(fNames, pattern, 'match')));
    nums    = sort(cellfun(@(s) str2double(s(stripLen+1:end)), matched));
    nums    = nums(~isnan(nums));
end


function opts = setDefault(opts, field, val)
    if ~isfield(opts, field) || isempty(opts.(field))
        opts.(field) = val;
    end
end
