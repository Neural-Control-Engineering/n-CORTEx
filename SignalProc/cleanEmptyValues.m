function cleanArray = cleanEmptyValues(A)
    A = cell2mat(A);
    cleanArray = A(~isnan(A));
    % cleanArray = A(A==[]);
    % cleanArray = cleanArray(cleanArray~=nan);
end