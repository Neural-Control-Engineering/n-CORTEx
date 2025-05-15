function s_out = subAssign(s_in, subFields, subField, value)
    % S = struct2table(S);
    % subFields = S.subs;
    % for i = 1:length(subFields)
    % subField = subFields{i};
    idx_subField = find(ismember(subFields,subField));
    nexSubField = subFields{idx_subField+1};
    s_out = struct;
    % if isfield(s,subField) || isprop(s, subField)
    if idx_subField == length(subFields) % BASE CASE

        s_out.(subField) = value;
        s_out = mergeStructs(s_in, s_out);

        % merge with existing subfields at this level
        if ~isfield(s_in,subField)
            s_out.(subField) = value;
        elseif ~isprop(s_in, subField)
            error("cannot assign dynamic property to nCORTEx application")
        elseif isfield(s_in, subField) || isprop(s_in, subField)

            s.(subField) = mergeStructs(s.(subField),value);
        end
    else
        try
            % s_out.(subField) = catstruct(s_in.(subField), subAssign(s_in.(nextSubField), subFields, nextSubField, value));
            s_out = mergeStructs(s_in, subAssign(s_in.(nextSubField), subFields, nextSubField, value)); % recurse to child
        catch e
            disp(getReport(e));
        end
    end
        % else
            
        % end
    % end
end