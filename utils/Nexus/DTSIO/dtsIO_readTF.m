function [TF, idxCond] =  dtsIO_readTF(nexon, dfID, IDX)        
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