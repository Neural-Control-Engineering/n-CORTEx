function minLength = nex_getDfMinLength(nexon, dfID)
    %  minLength to truncate long recordings if necessary
    minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID),"UniformOutput",true);
    minLength(minLength==0) = [];
    minLength = min(minLength);
end