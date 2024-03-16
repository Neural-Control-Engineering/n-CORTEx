function [trigNum, gateNum] = decodeTrigger(expmntLabel)
    expmntLabelFileParts = split(expmntLabel,'.');
    expmntFileName = expmntLabelFileParts(1);
    expmntLabelParts = split(expmntFileName,'_');
    trigPart = string(expmntLabelParts(end));
    trigNum = sscanf(trigPart,'t%d');
    gatePart = string(expmntLabelParts(end-1));
    gateNum = sscanf(gatePart,'g%d');    
end