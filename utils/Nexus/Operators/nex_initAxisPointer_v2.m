function DF = nex_initAxisPointer_v2(DF)
    % loop through ax fields and initiate ptr for each
    axFields = fieldnames(DF.ax);
    df = DF.df;
    dimsTaken = [];
    for i = 1:length(axFields)
        axField = axFields{i};
        ax = DF.ax.(axField);
        axLen = length(ax);
        dim = find(axLen==size(df));        
        if ndims(dim) > 1
            for j = 1:length(dim)
                axDim = dim(j);
                if ~ismember(axDim,dimsTaken)
                    DF.ptr.(axField).dim = axDim;
                    dimsTaken = [dimsTaken, axDim]; 
                    break
                end
            end
        else
            DF.ptr.(axField).dim = dim;
            dimsTaken = [dimsTaken, dim];                
        end
        DF.ptr.(axField).value=1;       
    end
    % upgrade to nexPtr
    DF.ptr = nexObj_ptr(DF.ptr);
end
