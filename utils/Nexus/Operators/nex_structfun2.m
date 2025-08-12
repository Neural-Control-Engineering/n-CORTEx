function outStruct = nex_structfun2(fun, S1, S2)
    % Ensure both structs have the same fieldnames
    fNames = fieldnames(S1);
    assert(isequal(fNames, fieldnames(S2)), 'Structs must have identical fields.');

    outStruct = struct();
    for i = 1:numel(fNames)
        fname = fNames{i};
        outStruct.(fname) = fun(S1.(fname), S2.(fname));
    end
end
