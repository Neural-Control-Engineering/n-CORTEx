function labelItem = parseSessionLabel(sessionLabel, labelField)
    labelParts = split(sessionLabel,"_");
    labelPart = labelParts(contains(labelParts,labelField));
    labelItem = split(labelPart,"--");
    if isempty(labelItem)
        labelItem = "";
    else
        labelItem = labelItem(2);
    end
end