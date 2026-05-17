function [mean_df, sem_df, ax_out, n_valid] = nexOp_accumulateTF(nexon, rowIdx, dfID, ptr, t_preBuff)
% Welford online mean/SEM over a set of trials — O(shape) memory regardless of N.
%
% Replaces the nexOp_compileTF → nexOp_averageTF pipeline for cases where
% loading all trials simultaneously is infeasible.  Alignment logic mirrors
% nexOp_compileTF exactly: sample-event scalars are read once upfront
% (lightweight), then nexOp_eventAlignDF is applied per trial.
%
%   nexon     : Nexon object
%   rowIdx    : row indices into nexon.console.BASE.DTS (numeric vector)
%   dfID      : dfID to read (without '_df' suffix)
%   ptr       : optional ptr struct for hyperslab read (ax-- filter)
%   t_preBuff : pre-buffer length in seconds (from nexObj.UserData.preBufferLen)
%
% Returns [] fields when no valid trials are found.

    if nargin < 4, ptr       = []; end
    if nargin < 5, t_preBuff = []; end

    mean_df = [];
    M2_df   = [];
    ax_out  = [];
    n_valid = 0;

    rowIdx = rowIdx(:)';

    % ── Read alignment scalars upfront (one bulk read, cheap) ────────────
    sampleEvents = [];
    fs_slrt      = [];
    doAlign      = false;
    try
        S_slrt       = nex_returnSelectionMask(nexon.console.SLRT.signals.eventAlignmentSelection);
        alignColTags = split(S_slrt.events, "_");
        ID_event     = alignColTags(1);
        sampleEvents = dtsIO_readTF(nexon, ID_event, rowIdx, 'simple');
        fs_slrt      = nexon.console.SLRT.signals.UserData.Fs;
        doAlign      = ~isempty(sampleEvents) && ~isempty(t_preBuff) && ~isempty(fs_slrt);
    catch
    end

    % ── Per-trial accumulation ────────────────────────────────────────────
    for k = 1:numel(rowIdx)
        % Read one trial (hyperslab-constrained by ptr if supplied)
        try
            DF = dtsIO_readDF(nexon, dfID, rowIdx(k), ptr);
        catch
            continue
        end
        if isempty(DF) || ~isfield(DF, 'df') || isempty(DF.df)
            continue
        end

        % Event alignment (mirrors nexOp_compileTF)
        if doAlign
            se = [];
            try, se = sampleEvents{k}; catch, end
            if ~isempty(se)
                try
                    DF = nexOp_eventAlignDF(DF, se, fs_slrt, t_preBuff, 1);
                catch
                end
            end
        end

        df_k = double(DF.df);

        % First valid trial: seed accumulators
        if n_valid == 0
            ax_out  = DF.ax;
            mean_df = df_k;
            M2_df   = zeros(size(df_k));
            n_valid = 1;
            continue
        end

        % Shape mismatch after alignment: trim trailing elements to reference
        if ~isequal(size(df_k), size(mean_df))
            df_k = trimToRef(df_k, size(mean_df));
            if isempty(df_k), continue; end
        end

        % Welford update (works for real and complex via conj generalisation)
        n_valid  = n_valid + 1;
        delta    = df_k - mean_df;
        mean_df  = mean_df + delta / n_valid;
        delta2   = df_k - mean_df;
        % real(conj(delta).*delta2) reduces to delta.*delta2 for real data
        % and accumulates sum(|x - mean|^2) for complex data
        M2_df    = M2_df + real(conj(delta) .* delta2);
    end

    if n_valid < 1 || isempty(mean_df)
        mean_df = [];  sem_df = [];  ax_out = [];
        return
    end

    if n_valid > 1
        sem_df = sqrt(max(M2_df, 0) / (n_valid - 1) / n_valid);
    else
        sem_df = zeros(size(mean_df));
    end

    % Restore complex SEM to match the mean's type when input was complex
    if ~isreal(mean_df)
        sem_df = real(sem_df);  % SEM is always a magnitude
    end
end

% ── Helpers ──────────────────────────────────────────────────────────────

function arr = trimToRef(arr, refSz)
% Trim arr to refSz by truncating oversized dimensions; return [] if any
% dimension of arr is shorter than refSz.
    sz = size(arr);
    if numel(sz) ~= numel(refSz) || any(sz < refSz)
        arr = [];
        return
    end
    for d = 1:numel(refSz)
        if sz(d) > refSz(d)
            idx    = repmat({':'}, 1, ndims(arr));
            idx{d} = 1:refSz(d);
            arr    = arr(idx{:});
        end
    end
end
