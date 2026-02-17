function categories = nexTract_signalTypeCategories(signalTypes)
    % for now use both 'affix' and 'category'
    matchCond = (strcmp(signalTypes(:,2),"affix") | strcmp(signalTypes(:,2),"category"));
    categories = convertCharsToStrings(signalTypes(matchCond,1));
end