function DF_out = nexOp_sqrtCounts(DF_in, args)
% nexOp_sqrtCounts  Bin spike rasters into coarse counts, then square-root.
%
% Run through nexTract / nexLaunch_extractPanel on a spike activity dfID (e.g.
% KS_spk_activity, unit x t x measure) to write a variance-stabilized patch dfID
% for dPCA and SSM. Order matters: counts are summed FIRST, then square-rooted
% (sqrt-then-pool is a different quantity). Poisson counts have variance = mean;
% sqrt makes variance roughly constant, as the LGSSM's fixed noise covariance
% assumes. Uses the unsmoothed raster, so no Gaussian kernel enters the data.
%
%   DF_in.df    : (unit x t x measure), or (unit x t) if already one measure
%   DF_in.ax    : .t (s), .unit, optional .chans (co-indexed with unit), .measure
%   DF_out.df   : (unit x tBin) sqrt(spike count per bin)
%   DF_out.ax.t : bin centers (s). A trailing partial bin is dropped.

    % CFG HEADER
    binWidth_ms = args.binWidth_ms; % default = 50

    X = DF_in.df;
    if isfield(DF_in.ax, 'measure') && ndims(X) == 3
        iRaster = find(string(DF_in.ax.measure) == "raster", 1);
        if isempty(iRaster)
            error('nexOp_sqrtCounts:noRaster', 'no "raster" entry on the measure axis.');
        end
        X = X(:, :, iRaster);
    end

    t  = DF_in.ax.t(:)';
    dt = median(diff(t));
    nPerBin = round(binWidth_ms / 1e3 / dt);
    if nPerBin < 1
        error('nexOp_sqrtCounts:binWidth', 'binWidth_ms %g is below the source bin %.3g ms.', binWidth_ms, dt*1e3);
    end
    nBins = floor(size(X, 2) / nPerBin);
    nKeep = nBins * nPerBin;

    counts = sum(reshape(double(X(:, 1:nKeep)), size(X, 1), nPerBin, nBins), 2);

    DF_out.df   = sqrt(reshape(counts, size(X, 1), nBins));
    DF_out.ax.unit = DF_in.ax.unit;
    DF_out.ax.t = mean(reshape(t(1:nKeep), nPerBin, nBins), 1);
    if isfield(DF_in.ax, 'chans')
        DF_out.ax.chans = DF_in.ax.chans;
    end
    DF_out = nex_initAxisPointer_v2(DF_out);
end
