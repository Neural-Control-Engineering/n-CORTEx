function argsLabel = nex_generateArgsLabel(args)
    % Initialize an empty string
    argsLabel = "";

    % Get the field names from the struct
    fields = fieldnames(args);

    % Iterate over each field
    for i = 1:numel(fields)
        k = fields{i};   % Get the key (field name)
        v = args.(k);    % Get the corresponding value

        % Replace underscores with dashes in the key
        k = strrep(k, "_", "-");

        % Convert numeric values to strings and replace '.' with 'p'
        if isnumeric(v)
            v = num2str(v);
            v = strrep(v, ".", "p");
        end

        % Append to argsLabel
        argsLabel = argsLabel + "_" + k + "--" + v;
    end
end
