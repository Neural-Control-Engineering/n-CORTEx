function out = readGroup(groupInfo, filename)
    out = struct();
    
    % Read datasets in this group
    for i = 1:numel(groupInfo.Datasets)
        dsetName = groupInfo.Datasets(i).Name;
        fullPath = fullfile(groupInfo.Name, dsetName);
        fullPath = regexprep(fullPath, '\\', '/'); % ensure forward slashes
        if strcmp(fullPath, '/')
            fullPath = ['/' dsetName];
        end
        out.(dsetName) = h5read(filename, fullPath);
    end
    
    % Recurse into subgroups
    for i = 1:numel(groupInfo.Groups)
        grpName = groupInfo.Groups(i).Name;
        shortName = regexp(grpName, '[^/]+$', 'match', 'once');
        out.(shortName) = readGroup(groupInfo.Groups(i), filename);
    end
end