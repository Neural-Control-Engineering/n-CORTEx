function cacheSel = redirectDestinations(cacheSel, newDest)
    for i = 1:height(cacheSel)
        dataDir = cacheSel(i,:).DataDir;
        modFields = fieldnames(dataDir);
        for j=1:length(modFields)
            mod = modFields{j};
            modDirs = dataDir.(mod);
            oldDest = modDirs.cloud;            
            [folder, name, ext] = fileparts(oldDest);
            folderParts = split(folder,filesep);
            projIdx = arrayfun(@(x) contains(x,"Project_"),folderParts);            
            projIdx = find(projIdx);
            newFolderParts = split(newDest,filesep);
            newFolderParts = [newFolderParts; folderParts(projIdx+1:end)];
            newDest = join(newFolderParts,filesep);
            newDest = fullfile(newDest,name);            
            dataDir.(mod).cloud = newDest;            
        end
        cacheSel(i,:).DataDir = dataDir;
    end    
end