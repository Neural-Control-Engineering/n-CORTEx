function dataDir = dataDir(path, matchingStr)
    masterDir = dir(path);
    masterDirNames = {dir(path).name}';
    dataDirIdx = cellfun(@(x) all(contains(x,matchingStr)), masterDirNames);
    dataDir = masterDir(dataDirIdx,:);
end