function dataSlice = sliceTnsr(tnsr, dim, idcs)
    dataSlice = [];
    for i = 1 : length(idcs)
        idx = idcs(i);
        % Initialize indices
        indices = cell(1, numel(size(tnsr)));
        indices{dim} = num2str(idx);    
        emptyIdx = cellfun(@isempty, indices);
        indices(emptyIdx) = {':'};    
        idxStr = strjoin(indices,',');        

        % Use dynamic indexing to get the data frame     
        cmd = sprintf("dataFrame = tnsr(%s);",idxStr);
        eval(cmd);
        dataSlice = cat(dim, dataSlice, dataFrame);
    end
end