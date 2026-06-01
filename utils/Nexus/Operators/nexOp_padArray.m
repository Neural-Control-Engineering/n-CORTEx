function C = nexOp_padArray(A, padLen, padVal)
    B = repelem(padVal, padLen)';
    C = [A; B];
end