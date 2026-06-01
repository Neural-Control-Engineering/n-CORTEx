function fit = kernel_specparam_brokenPowerLaw(ax, args)
% Smoothly broken power law aperiodic model with optional Gaussian periodic peaks.
%
% APERIODIC MODEL (in log10 power space, i.e. same domain as specparam):
%
%   log10 P(f) = OFF  −  EXP1·log10(f)
%              + (EXP1−EXP2)·log10(1 + f/FC1)
%              + (EXP2−EXP3)·log10(1 + f/FC2)
%              + ...
%
% Each correction term contributes exactly (EXP_k − EXP_{k+1}) of slope
% change at corner FC_k, and has no effect below that corner.
% Asymptotic behaviour:
%   f  ≪  FC1          →  slope = −EXP1
%   FC1 ≪ f ≪ FC2      →  slope = −EXP2
%   FC2 ≪ f ≪ FC3      →  slope = −EXP3   (and so on)
%
% Crucially: no slope compounding.  EXP_k parameters are the segment slopes
% directly — not incremental changes, not cumulative sums.  Shallowing
% transitions (EXP_{k+1} < EXP_k) are handled correctly.
%
% PERIODIC MODEL: Gaussian peaks added in log10 power space (specparam
% convention).  PW is peak height above aperiodic in log10 units; BW is
% the Gaussian sigma in Hz.
%
% PARAMETERS (detected dynamically from args — add FC_k / EXP_k fields to
% extend to more segments without changing this function):
%
%   OFF              global log10 power offset (at f = 1 Hz)
%   EXP1 … EXP_{N+1} segment slopes (one more than the number of corners)
%   FC1  … FC_N      corner frequencies in Hz, must be ascending
%   CF_j, PW_j, BW_j optional Gaussian peaks
%
% OUTPUT: fit in dB (10·log10 power), matching specparam-fitted PSD units.

    % CFG HEADER — defaults cover the single-corner (two-segment) case
    OFF  = args.OFF;   % default = 2.5
    EXP1 = args.EXP1;  % default = 1.0
    EXP2 = args.EXP2;  % default = 2.5
    FC1  = args.FC1;   % default = 50

    f_spec = ax.f(:)';              % enforce row vector
    f_spec = max(f_spec, 1e-10);    % guard log10(0)

    % ── Discover corner frequencies and segment exponents ─────────────────
    % Detect all FC_k and EXP_k fields present in args so the model scales
    % to however many segments were passed without code changes.
    fNames   = fieldnames(args);

    fcFields  = fNames(~cellfun(@isempty, regexp(fNames, '^FC\d+$',  'match')));
    expFields = fNames(~cellfun(@isempty, regexp(fNames, '^EXP\d+$', 'match')));

    fcNums  = sort(cellfun(@(s) str2double(s(3:end)),  fcFields));   % strip 'FC'
    expNums = sort(cellfun(@(s) str2double(s(4:end)), expFields));   % strip 'EXP'

    fcNums  = fcNums(~isnan(fcNums));
    expNums = expNums(~isnan(expNums));

    N = numel(fcNums);   % number of corner frequencies = number of segments − 1

    % ── Aperiodic component ───────────────────────────────────────────────
    % Baseline: pure power law with the first segment slope.
    log_f  = log10(f_spec);
    alpha1 = args.(sprintf('EXP%d', expNums(1)));
    fit_AP = OFF - alpha1 * log_f;

    % Add one correction term per corner frequency.
    % The k-th term transitions the slope from EXP_k to EXP_{k+1} at FC_k.
    for k = 1:N
        FC_k    = args.(sprintf('FC%d',  fcNums(k)));
        alpha_k = args.(sprintf('EXP%d', expNums(k)));

        if k < numel(expNums)
            alpha_k1 = args.(sprintf('EXP%d', expNums(k+1)));
        else
            % More FC fields than EXP fields: treat as no additional slope change.
            alpha_k1 = alpha_k;
        end

        % log10(1 + f/FC_k) is ~0 for f << FC_k and ~log10(f/FC_k) for f >> FC_k.
        % The prefactor (alpha_k - alpha_k1) is positive for steepening,
        % negative for shallowing — both are handled correctly.
        fit_AP = fit_AP + (alpha_k - alpha_k1) .* log10(1 + f_spec / FC_k);
    end

    fit_AP_dB = 10 * fit_AP;    % log10 power → dB

    % ── Periodic component (Gaussian peaks in log10 power space) ──────────
    % Peaks are parameterised the same way as specparam: CF (Hz), PW (log10
    % power height above aperiodic), BW (Gaussian sigma in Hz).
    cfFields  = fNames(~cellfun(@isempty, regexp(fNames, '^CF\d+$', 'match')));
    peakNums  = sort(cellfun(@(s) str2double(s(3:end)), cfFields));
    peakNums  = peakNums(~isnan(peakNums));

    fit_PE = zeros(1, numel(f_spec));
    for j = peakNums'
        CF = args.(sprintf('CF%d', j));
        PW = args.(sprintf('PW%d', j));
        BW = args.(sprintf('BW%d', j));
        fit_PE = fit_PE + PW * exp(-(f_spec - CF).^2 / (2 * BW^2));
    end

    % PW is in log10 power units → multiply by 10 to convert to dB before adding.
    fit = fit_AP_dB + 10 * fit_PE;
end
