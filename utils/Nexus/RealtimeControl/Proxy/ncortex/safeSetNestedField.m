function s = safeSetNestedField(s, fieldPath, value, delimiter)
    % PURELY-AI-GENERATED
    if nargin < 4
        delimiter = '--';
    end

    fields = strsplit(fieldPath, delimiter);
    current = s;

    % Walk the path except for the last field
    for i = 1:numel(fields)-1
        f = fields{i};

        if ~isfield(current, f) || ~isstruct(current.(f))
            % If field doesn't exist or isn't a struct, create it
            current.(f) = struct;
        end

        % Update the current pointer
        current = current.(f);
    end

    % Now assign the final value
    % Build the full reference using dynamic field names
    s = assignValueAtPath(s, fields, value);
end