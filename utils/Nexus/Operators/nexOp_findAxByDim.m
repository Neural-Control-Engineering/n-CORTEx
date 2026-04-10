function axID = nexOp_findAxByDim(ptr, dim)
    axFields = convertCharsToStrings(properties(ptr));    
    dims = [];
    for i = 1:length(axFields); dims = [dims; {ptr.(axFields(i)).dim}]; end
    idxMatch = cellfun(@(ptrDim) isequal(ptrDim,dim), dims, "UniformOutput",true);
    axID = axFields(idxMatch==1);
end