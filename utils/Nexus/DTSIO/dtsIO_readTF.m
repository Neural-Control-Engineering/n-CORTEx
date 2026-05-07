function [TF, idxCond] =  dtsIO_readTF(nexon, dfID, IDX, h5Modifier)     
    
    if nargin < 4
        h5Modifier=[];
    end

    dtsCols = nexon.console.BASE.DTS.Properties.VariableNames;
    try
        if ~ismember(dfID, dtsCols)
            TF = dtsIO_readTFH5(nexon.console.BASE.DTS, dfID, IDX, h5Modifier);
        else
            if isempty(IDX)
                % use the whole table
                numRows = height(nexon.console.BASE.DTS);
                idxCond = ones(numRows,1);
                IDX = idxCond;
            end
            idxCond = find(IDX==1);
            TF = arrayfun(@(idx) dtsIO_readDF(nexon, dfID, idx), idxCond, "UniformOutput", false);
            % TF = TF';
        end
    catch
        keyboard
    end
end