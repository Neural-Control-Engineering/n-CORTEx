function cacheSel = redirectDestinations(cacheSel, newDest)
    for i = 1:height(cacheSel)
        dDirType = class(cacheSel(i,:).DataDir);
        switch dDirType
            case "cell"
                dataDir = cacheSel(i,:).DataDir{1};
            otherwise
                dataDir = cacheSel(i,:).DataDir;
        end
        
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
            newDestMod = join(newFolderParts,filesep);
            newDestMod = fullfile(newDestMod,name);            
            dataDir.(mod).cloud = newDestMod;            
        end
        % cacheSel(i,:).DataDir = dataDir;
        switch dDirType
            case "cell"
                cacheSel(i,:).DataDir = {dataDir};
            otherwise
                cacheSel(i,:).DataDir = dataDir;
        end
    end    
end