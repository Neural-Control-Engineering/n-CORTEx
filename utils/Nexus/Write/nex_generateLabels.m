function [labelVals, labelKeys] = nex_generateLabels(nexon, sessionLabel, labelIDs)
    labelKeys = nex_enumerateSessionLabels(nexon, labelIDs);
    labels = arrayfun(@(x) parseSessionLabel(sessionLabel,x), labelIDs,"UniformOutput",true);
    % amend labels with labelID letter prefixes or hyphens
    amendCond = arrayfun(@(x) isStartsWithDigit(x), labels, "UniformOutput",true);
    labels(amendCond) = strcat(extractBefore(labelIDs(amendCond),2),labels(amendCond));
    labels_underscore = strrep(labels,"-","_");
    labelVals = arrayfun(@(x,y) labelKeys.(x).(y), labelIDs, labels_underscore,"UniformOutput",true)';
end