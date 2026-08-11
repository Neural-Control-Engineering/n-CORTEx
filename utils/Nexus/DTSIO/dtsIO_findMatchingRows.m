function matchingRows = dtsIO_findMatchingRows(keySel, TF)
    % Locate rows whose category value matches the selected key value(s).
    switch class(TF)
        case 'double'
            matchingRows = arrayfun(@(x) ismember(x, keySel), TF);
        case {'single','int8','int16','int32','int64', ...
              'uint8','uint16','uint32','uint64'}
            matchingRows = arrayfun(@(x) ismember(double(x), keySel), double(TF));
        case 'string'
            matchingRows = arrayfun(@(x) ismember(x, string(keySel)), TF);
        case 'cell'
            % Cell-per-trial (e.g. a scalar task variable stored as
            % cell-of-scalar via writeDataframe). Compare via string so numeric
            % and string cells both match against the selected keys, which share
            % the column's exact values.
            keyStr       = string(keySel);
            matchingRows = false(numel(TF), 1);
            for i = 1:numel(TF)
                v = TF{i};
                if ~isempty(v)
                    matchingRows(i) = ismember(string(v), keyStr);
                end
            end
        otherwise
            matchingRows = true(numel(TF), 1);   % unknown type — don't over-filter
    end
    matchingRows = matchingRows(:);
end