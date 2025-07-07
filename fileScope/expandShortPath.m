function longPath = expandShortPath(shortPath)
    if isstring(shortPath)
        shortPath = char(shortPath);
    end

    if ispc
        drive = shortPath(1:2);
        restPath = shortPath(3:end);
    else
        drive = '';
        restPath = shortPath;
    end

    parts = strsplit(restPath, filesep);

    if isempty(drive)
        curPath = filesep;
    else
        curPath = drive;
    end

    for i = 1:length(parts)
        part = parts{i};
        if isempty(part)
            continue
        end

        d = dir(curPath);

        % First try exact case-insensitive match
        idx = find(strcmpi({d.name}, part), 1);

        if isempty(idx)
            % If the short name has ~, try matching ignoring special chars
            if contains(part, '~')
                % Remove tildes and dashes for fuzzy matching
                cleanPart = regexprep(part, '[-~]', '');
                idx = find( ...
                    cellfun(@(x) contains(lower(x), lower(cleanPart)), {d.name}), 1);
            end
        end

        if isempty(idx)
            % fallback to original part if no match
            longName = part;
        else
            longName = d(idx).name;
        end

        curPath = fullfile(curPath, longName);
    end

    longPath = curPath;
end
