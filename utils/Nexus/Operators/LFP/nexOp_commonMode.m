function DF_out = nexOp_commonMode(DF_in, args)
% nexOp_commonMode  Uniform probe-wide common-mode (CM) split of an LFP DF.
%
% CM(t) = median (or mean) across channels at each time sample -- the same
% rule for every trial, unlike nex_pcaNoiseRm's per-trial adaptive PC1
% removal. Run it twice to get both patch dfIDs:
%   outMode = 1 -> CM-REMOVED LFP  (chans x t), df - CM     -> e.g. dfID "lfp_cmr"
%   outMode = 2 -> CM TRACE         (1 x t), chans = 0      -> e.g. dfID "lfp_cm"
% Feed both (and the original) through rtPMTM_magnitude_roll: route (a) LME
% on original power + CM power as a fixed effect; route (b) LME on CM-removed
% power (hypothesis ledger D2/D7/D8).
%
%   DF_in.df : (chans x t), DF_in.ax.t / .ax.chans (nested) or .t / .chans (flat)
%   useMedian: 1 = median (robust to a few loud channels), 0 = mean (= CAR)

    % CFG HEADER
    outMode = args.outMode; % default = 2
    useMedian = args.useMedian; % default = 1
    chanRange_start = args.chanRange_start; % default = 1
    chanRange_end = args.chanRange_end; % default = 384

    nested = isfield(DF_in, 'ax');
    if nested, ax = DF_in.ax; else, ax = struct('t', DF_in.t, 'chans', DF_in.chans); end

    chanSel = chanRange_start:min(chanRange_end, size(DF_in.df, 1));
    X = double(DF_in.df(chanSel, :));

    if useMedian
        cm = median(X, 1, 'omitnan');   % (1 x t)
    else
        cm = mean(X, 1, 'omitnan');
    end

    switch outMode
        case 1
            DF_out.df = X - cm;          % implicit expansion over channels
            chans = ax.chans(chanSel);
        case 2
            DF_out.df = cm;
            chans = 0;                   % single pseudo-channel: the probe common mode
        otherwise
            error('nexOp_commonMode:outMode', 'outMode must be 1 (removed) or 2 (CM trace).');
    end

    % Mirror the input schema (nested ax vs flat), as nex_pcaNoiseRm does.
    if nested
        DF_out.ax.t     = ax.t;
        DF_out.ax.chans = chans;
    else
        DF_out.t     = ax.t;
        DF_out.chans = chans;
    end
end
