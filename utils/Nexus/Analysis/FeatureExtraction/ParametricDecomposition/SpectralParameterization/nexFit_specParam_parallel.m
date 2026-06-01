function [DF_ap, DF_pe, DF_fit, specs, kernel_args] = nexFit_specParam_parallel(DF, spcpmArgs)

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

    ax_f      = DF.ax.f;
    dim_chans = DF.ptr.chans.dim;
    dim_t     = DF.ptr.t.dim;
    numDims   = ndims(DF.df);
    nChan     = length(ax_chans);
    nTime     = length(ax_t);

    spcpmArgs_fit = extractMethodCfg('specParam_multiExp');

    % Frequency axis for DF_fit (fitted range starts at fRange_start)
    fFitCond = ax_f >= spcpmArgs_fit.fRange_start;
    ax_f_fit = ax_f(fFitCond);
    nFreqFit = numel(ax_f_fit);
    nFreqAll = numel(ax_f);

    nApParams = 7;
    ap_labels = ["OFF","EXP1","EXP2","EXP3","FC1","FC2","FC3"];
    maxPeaks  = spcpmArgs_fit.numPeaks_max * 3;

    % Pre-extract all PSDs into (nChan, nTime, nFreq) so parfor gets a proper
    % sliced variable — only the i-th channel slice is sent to each worker.
    PSD_all = NaN(nChan, nTime, nFreqAll);
    for i = 1:nChan
        idx = repmat({':'}, 1, numDims-1);
        idx{dim_chans} = i;
        for j = 1:nTime
            idx{dim_t} = j;
            psd_ij = DF.df(idx{:});
            PSD_all(i, j, :) = psd_ij(:)';
        end
    end

    % Per-channel output cells — parfor can reduce over cell arrays freely.
    % Note: specParam_multiExp calls Python (OutOfProcess mode). Each parfor
    % worker is a separate MATLAB process and will start its own Python
    % interpreter, so parallel speedup requires sufficient system memory.
    AP_tmp  = cell(nChan, 1);
    PE_tmp  = cell(nChan, 1);
    FIT_tmp = cell(nChan, 1);

    parfor i = 1:nChan
        ap_i  = NaN(nTime, nApParams);
        pe_i  = NaN(nTime, maxPeaks, 3);
        fit_i = NaN(nTime, nFreqFit);

        psd_chan = squeeze(PSD_all(i, :, :));  % (nTime × nFreq)

        for j = 1:nTime
            df_psd = psd_chan(j, :);
            try
                [specs_ij, ~, psd_fit_ij] = specParam_multiExp(ax_f, df_psd, spcpmArgs_fit); %#ok<PFBNS>

                ap_i(j, :) = specs_ij(1:nApParams);

                pe_raw    = specs_ij(8:end);
                nTriplets = floor(numel(pe_raw) / 3);
                if nTriplets > 0
                    pe_mat_ij = reshape(pe_raw(1:nTriplets*3), 3, nTriplets)';
                    [~, so]   = sort(pe_mat_ij(:, 1));
                    pe_mat_ij = pe_mat_ij(so, :);
                    n_fill    = min(nTriplets, maxPeaks);
                    pe_i(j, 1:n_fill, :) = pe_mat_ij(1:n_fill, :);
                end

                psd_fit_dB = 10 * psd_fit_ij(:)';
                nFit       = numel(psd_fit_dB);
                fit_i(j, 1:min(nFit, nFreqFit)) = psd_fit_dB(1:min(nFit, nFreqFit));

            catch e
                warning('nexFit_specParam_parallel: chan=%d t=%d — %s', ax_chans(i), ax_t(j), e.message); %#ok<PFBNS>
            end
            py.gc.collect();
        end

        AP_tmp{i}  = ap_i;
        PE_tmp{i}  = pe_i;
        FIT_tmp{i} = fit_i;
    end

    % Reassemble cell slices into output matrices
    AP_mat  = NaN(nChan, nTime, nApParams);
    PE_mat  = NaN(nChan, nTime, maxPeaks, 3);
    FIT_mat = NaN(nChan, nTime, nFreqFit);
    for i = 1:nChan
        AP_mat(i, :, :)    = AP_tmp{i};
        PE_mat(i, :, :, :) = PE_tmp{i};
        FIT_mat(i, :, :)   = FIT_tmp{i};
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

    DF_fit.df       = FIT_mat;
    DF_fit.ax.chans = ax_chans;
    DF_fit.ax.t     = ax_t;
    DF_fit.ax.f     = ax_f_fit;

    specs       = [];
    kernel_args = [];
end
