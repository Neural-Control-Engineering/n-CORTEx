function labelItem = parseSessionLabel(sessionLabel, labelField)
    labelParts = split(sessionLabel,"_");
    labelPart = labelParts(contains(labelParts,labelField));
    labelItem = split(labelPart,"--");
    labelItem = labelItem(2);
end