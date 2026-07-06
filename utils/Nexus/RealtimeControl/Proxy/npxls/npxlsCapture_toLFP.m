function DF = npxlsCapture_toLFP(lfMat, fsStream, fsTarget)
% npxlsCapture_toLFP  Build an ad-hoc LFP dataframe from a captured imec LF band.
%
% DF = npxlsCapture_toLFP(lfMat, fsStream, fsTarget)
%
% Inputs:
%   lfMat    — (nSamp x nChan) int16 LF-band slice from a SpikeGL Fetch on the
%              imec stream (js=2). SpikeGLX serves the imec stream at the AP rate
%              with the LF channels sample-held, so lfMat arrives at fsStream, not
%              at the true LF rate — hence the decimation below.
%   fsStream — imec stream sample rate (Hz), e.g. 30000 (the AP rate).
%   fsTarget — desired LFP rate (Hz), default 500 (matches the offline extLFP
%              product so real-time and offline LFP DFs pool together).
%
% Output — a FLAT DF struct (df + axis fields, NO nested .ax). Flat is required:
% dtsIO_compileDTS drops the parent prefix when it recurses into a nested struct,
% so a nested .ax would foliate as ax_t/ax_chans instead of lfp_t/lfp_chans.
% Flat routes as lfp_df / lfp_t / lfp_chans and reads back via dtsIO_composeDF as
% DF.df + DF.ax.t / DF.ax.chans.
%   .df    — (nChan x nT) single, LF band decimated to fsTarget, channel-major
%            (matches extLFP's chan x time orientation)
%   .t     — (1 x nT) double, seconds from the capture-window start
%   .chans — (1 x nChan) double, physical channel index (1:nChan)

    if nargin < 3 || isempty(fsTarget), fsTarget = 500; end

    % NP2.0 (or LF not acquired) → no LF band; return an empty-but-shaped DF.
    if isempty(lfMat)
        DF.df = single([]); DF.t = []; DF.chans = [];
        return
    end

    lf   = single(lfMat);                     % nSamp x nChan
    dsLF = max(1, round(fsStream / fsTarget));

    if dsLF > 1
        % Boxcar (bin-average) decimation — anti-aliases with no toolbox
        % dependency. The probe's LF hardware filter already band-limits these
        % channels, so a boxcar is adequate for Phase 1. Reshape groups each
        % consecutive dsLF time samples (dim1) into nT bins (dim2) per channel
        % (dim3); mean over dim1 collapses each bin.
        nKeep = floor(size(lf,1) / dsLF) * dsLF;
        nT    = nKeep / dsLF;
        lf    = squeeze(mean(reshape(lf(1:nKeep,:), dsLF, nT, size(lf,2)), 1));  % nT x nChan
        fsOut = fsStream / dsLF;
    else
        nT    = size(lf,1);
        fsOut = fsStream;
    end

    DF.df    = lf.';                          % nChan x nT
    DF.t     = (0:nT-1) / fsOut;              % seconds from window start
    DF.chans = 1:size(DF.df,1);               % physical channel index
end
