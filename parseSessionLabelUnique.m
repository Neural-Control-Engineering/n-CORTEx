function uniqueVals = parseSessionLabelUnique(sessionLabels,key)
    % return unique items corresponding to the given key for the list of given
    % sessionLabels
    allVals = arrayfun(@(x) parseSessionLabel(x, key), sessionLabels, "UniformOutput",true);
    uniqueVals = unique((allVals));
end
