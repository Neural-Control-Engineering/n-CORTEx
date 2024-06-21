function expmntPath = compileExpmntPath(dataDir)
    expmntPath = dataDir.SLRT.cloud;
    expmntPath = split(expmntPath,filesep);
    expIdx = find(contains(expmntPath,"Project_")) + 2;
    expmntPath = expmntPath(1:expIdx);
    expmntPath = join(expmntPath,filesep);
end