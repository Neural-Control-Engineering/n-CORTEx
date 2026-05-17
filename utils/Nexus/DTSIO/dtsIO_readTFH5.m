function out = dtsIO_readTFH5(DTS, dfID, idxSel, modifier, ptr)
% Read a DTS column or HDF5 dfID across selected rows.
%
%   out = dtsIO_readTFH5(DTS, dfID)
%   out = dtsIO_readTFH5(DTS, dfID, idxSel)
%   out = dtsIO_readTFH5(DTS, dfID, idxSel, modifier)
%   out = dtsIO_readTFH5(DTS, dfID, idxSel, modifier, ptr)
%
%   modifier  : string or cellstr of flags (order-independent)
%     'simple'   — extract .df from each DF struct, return {N×1} cell
%     'parallel' — use parfor for multi-row HDF5 reads (safe: each worker
%                  opens its own read-only file handle; no shared state)
%
%   ptr       : optional plain struct with .(axName).range = [i1,i2].
%               Passed to dtsIO_composeDF for hyperslab reads on chunked
%               datasets. Must be a plain struct (not a handle) for parfor
%               broadcast safety — use ptrToStruct before calling if needed.
%
%   Combining flags: dtsIO_readTFH5(DTS, dfID, idx, {'simple','parallel'})
%
%   DTS      : manifest table (disk-backed) or in-memory DTS
%   dfID     : column name or HDF5 dfID string
%   idxSel   : empty → all rows; logical or numeric row selector
%
% Returns the raw column slice if dfID is a direct table column.
% Returns a DF struct (scalar idxSel) or {N×1} cell of DF structs otherwise.
% With 'simple': extracts .df from each struct; missing trials → [] (not dropped).

    if nargin < 5, ptr = []; end
    dfID      = char(dfID);
    doSimple   = hasFlag(modifier, 'simple');
    doParallel = hasFlag(modifier, 'parallel');

    % Resolve row indices
    if nargin < 3 || isempty(idxSel)
        rows = (1:height(DTS))';
    elseif islogical(idxSel)
        rows = find(idxSel);
    else
        rows = idxSel(:);
    end

    % Direct table column — manifest metadata, strings, signal_types, etc.
    if ismember(dfID, string(DTS.Properties.VariableNames))
        col = DTS.(dfID);
        if iscell(col)
            out = col(rows);
        else
            out = col(rows, :);
        end
        return;
    end

    % Scalar case — no parallelism needed
    if isscalar(rows)
        out = dtsIO_composeDF(DTS, dfID, rows, ptr);
        if doSimple, out = extractDF(out); end
        return;
    end

    % Multi-row: parallel or serial
    out = cell(numel(rows), 1);
    if doParallel
        ensurePool();
        % Each worker independently opens a read-only file handle — safe.
        % DTS is a plain table (value type), broadcast to all workers.
        % ptr must be a plain struct (not a handle) for broadcast — callers
        % are responsible for converting nexObj_ptr before calling.
        parfor i = 1:numel(rows)
            DF = dtsIO_composeDF(DTS, dfID, rows(i), ptr);
            if isstruct(DF) && ~isempty(fieldnames(DF))
                out{i} = DF;
            end
        end
    else
        for i = 1:numel(rows)
            DF = dtsIO_composeDF(DTS, dfID, rows(i), ptr);
            if isstruct(DF) && ~isempty(fieldnames(DF))
                out{i} = DF;
            end
        end
    end

    if doSimple
        out = cellfun(@extractDF, out, 'UniformOutput', false);
    end
end

% ── Local helpers ──────────────────────────────────────────────────────────

function arr = extractDF(c)
    if isstruct(c) && isfield(c, 'df')
        arr = c.df;
    else
        arr = [];
    end
end

function ensurePool()
% Start a local parallel pool if none is already running.
    if isempty(gcp('nocreate'))
        parpool('local');
    end
end

function tf = hasFlag(modifier, flag)
% Returns true if modifier (string, char, or cellstr) contains flag.
    if nargin < 1 || isempty(modifier)
        tf = false;
    elseif iscell(modifier)
        tf = any(cellfun(@(m) strcmpi(char(m), flag), modifier));
    else
        tf = strcmpi(char(modifier), flag);
    end
end
