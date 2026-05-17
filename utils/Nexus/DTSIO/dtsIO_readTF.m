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
        end
    catch e
        keyboard
    end
end