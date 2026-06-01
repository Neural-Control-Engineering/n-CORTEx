function df_cf = psdIO_readCornerFrequencies(f_psd, df_psd, cfConvention)
% cfConvention controls which frequency is reported at each regime boundary:
%   'start' — last point still in the outgoing regime  (your convention A)
%   'end'   — first point of the incoming regime        (your convention B)
%   'mid'   — geometric mean of start and end in log-f  (default)
%             bounds the error to ≤ half the inter-sample spacing;
%             symmetric regardless of which regime is considered primary

    %% CONFIG
    K = 2;                  % number of spectral regimes (tune this)
    minTransitionGap = 10;  % Hz — debounce analog, now geometrically motivated
    smoothFactor = 0.15;
    if nargin < 3 || isempty(cfConvention)
        cfConvention = 'mid';
    end

    %% Smooth (keep your ASLS)
    DF_psd.df = df_psd;
    args = extractMethodCfg('smooth_ASLS');
    DF_smooth = smooth_ASLS(DF_psd, args);
    df_smooth = DF_smooth.df';

    %% Resample on log scale
    % numTicks = 250;
    numTicks = length(df_psd);
    f_ticks = unique(floor(logspace(log10(f_psd(2)), log10(f_psd(end)-1), numTicks)));
    df_smooth_resamp = df_smooth(f_ticks);
    f_resamp = f_psd(f_ticks)';

    %% Work in log-log space — local spectral slopes
    log_f   = log10(f_resamp);
    log_psd = log10(abs(df_smooth_resamp));  % abs guard for safety

    local_slopes = diff(log_psd(:)) ./ diff(log_f(:));  % always column; power-law exponents per bin
    f_slopes = f_resamp(1:end-1);                        % freq axis for slopes

    %% K-means on slopes → find spectral regimes
    % Guard: numel may be fine but shape matters — local_slopes(:) is always
    % a column so kmeans sees numel(local_slopes) observations, not 1.
    K = min(K, numel(local_slopes) - 1);
    if K < 2
        warning('psdIO_readCornerFrequencies: only %d slope points after resampling — cannot cluster. Returning empty.', numel(local_slopes));
        df_cf = [];
        return;
    end
    rng(42);  % reproducibility
    [cluster_idx, centroids, sumd] = kmeans(local_slopes(:), K, ...
        'Replicates', 10, ...
        'Distance',   'sqeuclidean');

    %% Find regime transitions
    transition_mask = diff(cluster_idx) ~= 0;
    transition_idx  = find(transition_mask);

    % Convention: each transition sits between two consecutive slope points.
    % 'start' = last point of the outgoing regime (may under-shoot the true break).
    % 'end'   = first point of the incoming regime (may over-shoot).
    % 'mid'   = geometric mean in log-f — symmetric, error ≤ half inter-sample gap.
    idx_end = min(transition_idx + 1, numel(f_slopes));  % guard against edge
    f_A = f_slopes(transition_idx);
    f_B = f_slopes(idx_end);
    switch lower(cfConvention)
        case 'start',  f_transitions = f_A;
        case 'end',    f_transitions = f_B;
        case 'mid',    f_transitions = 10 .^ (0.5 * (log10(f_A) + log10(f_B)));
        otherwise,     error('psdIO_readCornerFrequencies: unknown cfConvention ''%s''. Use ''start'', ''end'', or ''mid''.', cfConvention);
    end

    %% Debounce: suppress transitions within minTransitionGap Hz of each other
    f_cf = [];
    last_cf = -Inf;
    for i = 1:length(f_transitions)
        if (f_transitions(i) - last_cf) >= minTransitionGap
            f_cf(end+1) = f_transitions(i);
            last_cf = f_transitions(i);
        end
    end

    %% Diagnostics
    % figure;
    % subplot(2,1,1);
    % semilogx(f_psd, df_psd, 'Color', [0.7 0.7 0.7]); hold on;
    % semilogx(f_resamp, df_smooth_resamp, 'b', 'LineWidth', 1.5);
    % for cf = f_cf
    %     xline(cf, 'r--', sprintf('%.0f Hz', cf), 'LabelVerticalAlignment','bottom');
    % end
    % xlabel('Frequency (Hz)'); ylabel('Power'); title('PSD + Corner Frequencies');
    % 
    % subplot(2,1,2);
    % scatter(f_slopes, local_slopes, 30, cluster_idx, 'filled');
    % colormap(lines(K)); colorbar;
    % set(gca, 'XScale', 'log');
    % hold on;
    % for cf = f_cf
    %     xline(cf, 'r--');
    % end
    % xlabel('Frequency (Hz)'); ylabel('Log-log slope (spectral exponent)');
    % title(sprintf('K=%d regime clustering | centroids: %s', K, mat2str(round(centroids,2))));

    df_cf = f_cf;
end