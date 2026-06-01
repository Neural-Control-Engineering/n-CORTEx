function categories = nexTract_sessionLabelCategories(sessionLabel)
    sessionLabel_parts = split(sessionLabel,["--","_"]);
    % take every other part as the associated category (except g)
    categories = convertCharsToStrings(sessionLabel_parts([1:2:end-1]));
end