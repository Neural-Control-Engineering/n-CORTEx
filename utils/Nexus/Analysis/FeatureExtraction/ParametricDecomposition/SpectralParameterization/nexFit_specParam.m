function [DF_ap, DF_pe, DF_fit, specs, kernel_args] = nexFit_specParam(DF, spcpmArgs)

    % CFG HEADER
    fitMode  = spcpmArgs.fitMode;   % default = 'multiExp'
    scale    = spcpmArgs.scale;     % default = 'volume'
    keepInput = spcpmArgs.keepInput; % default = 0

    if ~isfield(DF,'ptr')
        DF.ptr = nexInit_axisPointer(DF.df, DF.ax);
    end

    switch scale
        case 'single'
            ax_chans = DF.ptr.chans.indices;
            ax_t     = DF.ptr.t.indices;
        case 'volume'
            ax_chans = DF.ax.chans;
            ax_t     = DF.ax.t;
    end

    ax_f     = DF.ax.f;
    dim_chans = DF.ptr.chans.dim;
    dim_t    = DF.ptr.t.dim;
    numDims  = ndims(DF.df);
    nChan    = length(ax_chans);
    nTime    = length(ax_t);

    spcpmArgs_fit = extractMethodCfg('specParam_multiExp');

    % Frequency axis for DF_fit (fitted range starts at fRange_start)
    fFitCond  = ax_f >= spcpmArgs_fit.fRange_start;
    ax_f_fit  = ax_f(fFitCond);
    nFreqFit  = numel(ax_f_fit);

    % DF_ap: [OFF, EXP1, EXP2, EXP3, FC1, FC2, FC3] — 7 params, fixed by spcpmIO_specs2kernel
    nApParams = 7;
    ap_labels = ["OFF","EXP1","EXP2","EXP3","FC1","FC2","FC3"];

    % DF_pe: (nChan, nTime, maxPeaks, 3=[CF,PW,BW]), NaN-padded, sorted by CF
    % max peaks = numPeaks_max per segment × 3 segments (kernel convention)
    maxPeaks  = spcpmArgs_fit.numPeaks_max * 3;

    % Pre-allocate
    AP_mat  = NaN(nChan, nTime, nApParams);
    PE_mat  = NaN(nChan, nTime, maxPeaks, 3);
    FIT_mat = NaN(nChan, nTime, nFreqFit);

    for i = 1:nChan
        idx = repmat({':'}, 1, numDims-1);
        % idx{dim_chans} = ax_chans(i);
        idx{dim_chans}=i;
        for j = 1:nTime
            % idx{dim_t} = ax_t(j);
            idx{dim_t} = j;
            df_psd = DF.df(idx{:});
            try
                [specs_ij, ~, psd_fit_ij] = specParam_multiExp(ax_f, df_psd(:)', spcpmArgs_fit);

                % Aperiodic: specs_ij(1:7) = [OFF, EXP1, EXP2, EXP3, FC1, FC2, FC3]
                AP_mat(i, j, :) = specs_ij(1:nApParams);

                % Peaks: specs_ij(8:end) are [CF,PW,BW] triplets (zeros removed by spcpmIO)
                pe_raw = specs_ij(8:end);
                nTriplets = floor(numel(pe_raw) / 3);
                if nTriplets > 0
                    pe_mat_ij = reshape(pe_raw(1:nTriplets*3), 3, nTriplets)';  % (nTriplets × 3)
                    [~, so] = sort(pe_mat_ij(:, 1));                             % sort by CF
                    pe_mat_ij = pe_mat_ij(so, :);
                    n_fill = min(nTriplets, maxPeaks);
                    PE_mat(i, j, 1:n_fill, :) = pe_mat_ij(1:n_fill, :);
                end

                % Fit PSD: spec2psd returns log10-power; ×10 → dB (same units as raw df_psd)
                psd_fit_dB = 10 * psd_fit_ij(:)';
                nFit = numel(psd_fit_dB);
                FIT_mat(i, j, 1:min(nFit, nFreqFit)) = psd_fit_dB(1:min(nFit, nFreqFit));

            catch e
                warning('nexFit_specParam: chan=%d t=%d — %s', ax_chans(i), ax_t(j), e.message);
            end
        end
    end

    % Package into DF structs
    DF_ap.df       = AP_mat;
    DF_ap.ax.chans = ax_chans;
    DF_ap.ax.t     = ax_t;
    DF_ap.ax.param = ap_labels;

    DF_pe.df       = PE_mat;
    DF_pe.ax.chans = ax_chans;
    DF_pe.ax.t     = ax_t;
    DF_pe.ax.peak  = (1:maxPeaks)';
    DF_pe.ax.param = ["CF","PW","BW"];

    DF_fit.df      = FIT_mat;
    DF_fit.ax.chans = ax_chans;
    DF_fit.ax.t    = ax_t;
    DF_fit.ax.f    = ax_f_fit;

    % Volume-level specs/kernel_args not meaningful; callers use the DF outputs
    specs       = [];
    kernel_args = [];
end
