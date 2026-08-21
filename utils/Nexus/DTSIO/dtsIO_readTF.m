function [TF, idxCond] = dtsIO_readTF(nexon, dfID, IDX, h5Modifier, ptr)

    if nargin < 4, h5Modifier = []; end
    if nargin < 5, ptr = []; end

    dtsCols = nexon.console.BASE.DTS.Properties.VariableNames;
    try
        if ~ismember(dfID, dtsCols)
            TF = dtsIO_readTFH5(nexon.console.BASE.DTS, dfID, IDX, h5Modifier, ptr);
        else
            if isempty(IDX)
                numRows = height(nexon.console.BASE.DTS);
                idxCond = ones(numRows,1);
                IDX = idxCond;
            end
            idxCond = find(IDX==1);
            TF = arrayfun(@(idx) dtsIO_readDF(nexon, dfID, idx, ptr), idxCond, "UniformOutput", false);
            if strcmp(h5Modifier, 'simple')
                TF = cellfun(@(d) extractDF(d), TF, 'UniformOutput', false);
            end
        end
    catch e
        keyboard
    end
end

function out = extractDF(d)
% Mirror the 'simple' behaviour of dtsIO_readTFH5: pull .df if present,
% otherwise return the raw value (e.g. scalars stored directly in the DTS).
    if isstruct(d) && isfield(d, 'df')
        out = d.df;
    else
        out = d;
    end
end