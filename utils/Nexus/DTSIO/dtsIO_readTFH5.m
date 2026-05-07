function out = dtsIO_readTFH5(DTS, dfID, idxSel, modifier)
% Read a DTS column or HDF5 dfID across selected rows.
%
%   out = dtsIO_readTFH5(DTS, dfID)                    % all rows
%   out = dtsIO_readTFH5(DTS, dfID, idxSel)            % selected rows
%   out = dtsIO_readTFH5(DTS, dfID, idxSel, 'simple')  % vertically concat .df arrays
%
%   DTS      : manifest table (disk-backed) or in-memory DTS
%   dfID     : column name or HDF5 dfID string
%   idxSel   : empty → all rows; logical or numeric row selector
%   modifier : 'simple' — extract .df from each DF struct and vcat into one array
%
% Returns the raw column slice if dfID is a direct table column (metadata,
% strings, signal_types, etc.).  Returns a DF struct (scalar) or {N×1} cell
% of DF structs (multiple rows) when dfID resolves to per-trial data in HDF5
% or matching _df/_ax columns in an in-memory DTS.

    dfID      = char(dfID);
    doSimple  = nargin >= 4 && ischar(modifier) && strcmpi(modifier, 'simple');

    % Resolve row indices
    if nargin < 3 || isempty(idxSel)
        rows = (1:height(DTS))';
    elseif islogical(idxSel)
        rows = find(idxSel);
    else
        rows = idxSel(:);
    end

    % Direct table column — manifest metadata, string labels, signal_types, etc.
    if ismember(dfID, string(DTS.Properties.VariableNames))
        col = DTS.(dfID);
        if iscell(col)
            out = col(rows);
        else
            out = col(rows, :);
        end
        return;
    end

    % Per-trial DF read via compose path (handles disk-backed HDF5 and in-memory)
    if isscalar(rows)
        out = dtsIO_composeDF(DTS, dfID, rows);
        if doSimple
            out = extractDF(out);
        end
        return;
    end

    out = cell(numel(rows), 1);
    for i = 1:numel(rows)
        DF = dtsIO_composeDF(DTS, dfID, rows(i));
        if ~isempty(fieldnames(DF))
            out{i} = DF;
        end
    end

    if doSimple
        out = cellfun(@(c) extractDF(c), out, 'UniformOutput', false);
    end
end

function arr = extractDF(c)
    if isstruct(c) && isfield(c, 'df')
        arr = c.df;
    else
        arr = [];
    end
end
