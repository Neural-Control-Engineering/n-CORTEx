function relPath = locateSessionFile(filePath, sessionLabel)
    fileDir = dir(filePath);
    fileDir = struct2table(fileDir);
    % check for sessionlabel
    relPath = [];
    if any(contains(fileDir.name,sessionLabel))
        relPath = string(filePath);
    else
        % check subdirs
        subFldrs = fileDir(3:end,fileDir.isdir==1);
        if isempty(subFldrs)
            relPath = [];
        else
            for i = 1:height(subFldrs)
                subFldr = subFldrs.name{i};
                relPath = [relPath; locateSessionFile(fullfile(filePath,subFldr),sessionLabel)];
            end        
        end
    end
end