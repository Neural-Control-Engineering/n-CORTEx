function TF =  dtsIO_readTF(nexon, dfID, IDX)        
    idxCond = find(IDX==1);
    TF = arrayfun(@(idx) dtsIO_readDF(nexon, dfID, idx), idxCond, "UniformOutput", false);
    % TF = TF';
end