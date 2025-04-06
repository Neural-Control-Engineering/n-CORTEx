function fileName_extRm = rmExtension(fileName)
    fileName_extRm = split(fileName,".");
    fileName_extRm = fileName_extRm{1};
end