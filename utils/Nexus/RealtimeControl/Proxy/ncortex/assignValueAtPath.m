function s = assignValueAtPath(s, fields, value)
    % PURELY AI-GENERATED:
    % Base case: single field
    if isscalar(fields)
        s.(fields{1}) = value;
    else
        f = fields{1};
        if ~isfield(s, f) || ~isstruct(s.(f))
            s.(f) = struct;
        end
        s.(f) = assignValueAtPath(s.(f), fields(2:end), value);
    end
end