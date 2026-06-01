function [V, F] = nexOp_sliceFactors(row, factorSel)
    % row = struct2table(row); % assumed passed as struct for rowfun operation
    % factorSel=struct2table(factorSel); % assumed passed as struct for rowfun operation
    numFactors=height(factorSel);
    V = []; % value vector
    F = [];
    for i = 1:numFactors
        factorID = factorSel.ID(i);
        factorProp = factorSel.Property(i);
        % get dimension        
        ptr = row.ptr{1};        
        ax = row.ax{1};
        factorDim = ptr.(factorProp).dim;
        IDDim = find(strcmp(ax.(factorProp),factorID));
        % get value
        df = row.df{1};
        slice = repmat({':'},1,ndims(df));
        slice{factorDim} = IDDim;        
        factorVal = df(slice{:});
        % assign result to corresponding dim (by order)        
        if ~isempty(factorVal)            
            V = [V, factorVal];
            F = [F, factorID];   
        else
            V = [V, nan];
            F = [F, ""];
        end
    end

end