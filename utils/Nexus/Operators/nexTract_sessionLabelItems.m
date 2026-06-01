function items = nexTract_sessionLabelItems(sessionLabel)
    sessionLabel_parts = split(sessionLabel,["--","_"]);
    % take every other part as the associated category
    items = convertCharsToStrings(sessionLabel_parts([2:2:end-1]));
end