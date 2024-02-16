function trncTnsr = truncTnsr(tnsr, N, dim)
    if size(tnsr,dim) > N                
        % Initialize indices
        indices = cell(1, numel(size(tnsr)));
        % indices{dim} = num2str(idx);    
        indices{dim} = sprintf('1:%d',N);
        emptyIdx = cellfun(@isempty, indices);
        indices(emptyIdx) = {':'};    
        idxStr = strjoin(indices,',');     
        cmd = sprintf("trncTnsr = tnsr(%s);",idxStr);
        eval(cmd);
    else
        trncTnsr = tnsr;
    end
end