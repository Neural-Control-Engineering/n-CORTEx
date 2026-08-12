function DF_out = nexOp_unitsToChannels(DF, canonicalChans, aggMode)
% Map a per-unit spike DF onto a fixed per-channel feature axis.
%
%   DF_out = nexOp_unitsToChannels(DF, canonicalChans, aggMode)
%
% Spike-sorted 'unit' ids are session-local and ragged (different count/identity
% per session), so they can't serve as a stable PCA feature axis. Each unit sits
% on a root channel (the co-indexed 'chans' label, length n_units). This
% aggregates each unit's activity into its channel, producing a df whose unit
% dimension is replaced by a FIXED canonical channel axis — session/subject-
% invariant, so all trials present the same feature vector regardless of which
% units were sorted.
%
%   canonicalChans : fixed channel-id vector (e.g. 1:nProbeChan). Units on a
%                    channel not in this set are dropped. Empty → use
%                    sort(unique(DF.ax.chans)) (fit-observed channels only).
%   aggMode        : how units on the same channel combine (default "sum"):
%                    "sum"   — Σ activity of the units on the channel (multi-unit)
%                    "mean"  — sum / (units on the channel)
%                    "max"   — elementwise max across the units on the channel
%                    "count" — number of units on the channel (constant over t)
%
% No-op if the DF has no 'unit' dimension or no 'chans' label.

    if nargin < 3 || isempty(aggMode), aggMode = "sum"; end
    aggMode = lower(string(aggMode));

    DF_out = DF;
    if ~isstruct(DF) || ~isfield(DF, 'df') || isempty(DF.df) || ~isfield(DF, 'ax')
        return;
    end
    ax = DF.ax;
    if ~isfield(ax, 'chans') || ~isfield(ax, 'unit')
        return;   % not a per-unit spike DF
    end

    df = DF.df;
    nd = ndims(df);

    % Locate the unit dimension (prefer the pointer; fall back to a size match
    % that isn't the D1/time-like axis).
    unitDim = [];
    try, unitDim = DF.ptr.unit.dim; catch, end
    if isempty(unitDim)
        cand = find(size(df) == numel(ax.unit));
        if isfield(ax, 't')
            cand = cand(cand ~= find(size(df) == numel(ax.t), 1));
        end
        if ~isempty(cand), unitDim = cand(1); end
    end
    if isempty(unitDim) || unitDim > nd || size(df, unitDim) ~= numel(ax.chans)
        return;   % can't align units <-> chans safely
    end

    chansPerUnit = double(ax.chans(:));
    if nargin < 2 || isempty(canonicalChans)
        canonicalChans = unique(chansPerUnit);
    end
    canonicalChans = double(canonicalChans(:));
    nChan = numel(canonicalChans);

    % Accumulate sum / max / count over the units on each channel in one pass.
    outSize          = size(df);
    outSize(unitDim) = nChan;
    accSum = zeros(outSize, 'like', df);
    accMax = [];
    cnt    = zeros(1, nChan);
    [tf, loc] = ismember(chansPerUnit, canonicalChans);

    for u = 1:numel(chansPerUnit)
        if ~tf(u), continue; end          % unit's channel not in canonical set — drop
        c      = loc(u);
        idxIn  = repmat({':'}, 1, nd); idxIn{unitDim}  = u;
        idxOut = repmat({':'}, 1, nd); idxOut{unitDim} = c;
        slice  = df(idxIn{:});
        accSum(idxOut{:}) = accSum(idxOut{:}) + slice;
        cnt(c)            = cnt(c) + 1;
        if aggMode == "max"
            if isempty(accMax), accMax = -inf(outSize, 'like', df); end
            accMax(idxOut{:}) = max(accMax(idxOut{:}), slice);
        end
    end

    switch aggMode
        case "sum"
            dfOut = accSum;
        case "mean"
            dfOut = accSum;
            for c = 1:nChan
                if cnt(c) > 1
                    idxOut = repmat({':'}, 1, nd); idxOut{unitDim} = c;
                    dfOut(idxOut{:}) = dfOut(idxOut{:}) / cnt(c);
                end
            end
        case "max"
            if isempty(accMax), accMax = zeros(outSize, 'like', df); end
            accMax(~isfinite(accMax)) = 0;    % channels with no units (-inf) -> 0
            dfOut = accMax;
        case "count"
            dfOut = zeros(outSize, 'like', df);
            for c = 1:nChan
                if cnt(c) > 0
                    idxOut = repmat({':'}, 1, nd); idxOut{unitDim} = c;
                    dfOut(idxOut{:}) = cnt(c);
                end
            end
        otherwise
            error("nexOp_unitsToChannels:aggMode", ...
                  "unknown aggMode '%s' (use sum/mean/max/count)", aggMode);
    end

    % Rebuild: 'chans' becomes the feature dimension; 'unit' is gone.
    DF_out.df  = dfOut;
    DF_out.ax  = rmfield(ax, 'unit');
    DF_out.ax.chans = canonicalChans;
    DF_out.ptr = nexInit_axisPointer(DF_out.df, DF_out.ax);
end
