function sessionLabel = editSessionLabel(sessionLabel, labelField, newLabel)
    labelParts = split(sessionLabel,"_");
    labelPart = labelParts(contains(labelParts,labelField));
    labelItem = split(labelPart,"--");
    % labelItem = labelItem(2);
    labelItem{2} = newLabel;
    % join back and string together
    labelPart = join(labelItem,"--");
    labelParts(contains(labelParts,labelField)) = labelPart;
    sessionLabel = join(labelParts,"_");
    sessionLabel = sessionLabel{1};
end