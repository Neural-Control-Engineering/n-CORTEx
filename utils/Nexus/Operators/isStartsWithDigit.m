function res =  isStartsWithDigit(str)
    res = ~isempty(regexp(str, '^\d', 'once'));
end