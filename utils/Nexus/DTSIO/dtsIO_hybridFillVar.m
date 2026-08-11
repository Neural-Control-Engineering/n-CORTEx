function TF = dtsIO_hybridFillVar(dataObj, varID, idxSel, TF)
% Hybrid-DTS fill for a per-trial "var" (direct manifest column).
%
%   TF = dtsIO_hybridFillVar(dataObj, varID, idxSel, TF)
%
% In a hybrid DTS a task variable can be an empty manifest cell for a
% disk-backed row — its value actually lives in HDF5 (e.g. yesterday's trials,
% whose manifest cell was only created when in-memory capture rows were merged
% in). Given TF already read from the manifest column, this fills the missing
% entries per-row from HDF5, only for disk-backed rows (h5_path set). In-memory
% rows (manifest value present) are left untouched.
%
% No-op for a pure in-memory DTS or when nothing is missing. Shared by
% dtsIO_readTF_category (mask matching) and nexOp_enumerateCategory (item list)
% so both see the same values.

    if istable(dataObj)
        DTS = dataObj;
    else
        DTS = dataObj.console.BASE.DTS;
    end
    if isempty(DTS) || ~istable(DTS) || ...
            ~ismember('h5_path', string(DTS.Properties.VariableNames))
        return;   % not disk-backed — manifest read is already complete
    end

    % Absolute row indices in TF order.
    if ischar(idxSel) && strcmp(idxSel, ':')
        rows = (1:height(DTS))';
    elseif islogical(idxSel)
        rows = find(idxSel);
    else
        rows = idxSel(:);
    end

    for k = 1:min(numel(rows), numel(TF))
        r = rows(k);
        if ~localIsMissing(TF, k),                 continue; end
        if strlength(string(DTS.h5_path(r))) == 0, continue; end   % in-memory row
        try
            DF = dtsIO_readHDF5(DTS, char(varID), r, []);
        catch
            continue;
        end
        if isstruct(DF) && isfield(DF, 'df') && ~isempty(DF.df)
            v = DF.df;
            if ~isscalar(v), v = v(1); end
            TF = localSet(TF, k, v);
        end
    end
end

function tf = localIsMissing(TF, k)
    if isnumeric(TF)
        tf = isnan(TF(k));
    elseif isstring(TF)
        tf = ismissing(TF(k)) || TF(k) == "";
    elseif iscell(TF)
        tf = isempty(TF{k});
    else
        tf = false;
    end
end

function TF = localSet(TF, k, v)
    if isnumeric(TF)
        TF(k) = double(v);
    elseif isstring(TF)
        TF(k) = string(v);
    elseif iscell(TF)
        TF{k} = v;
    end
end
