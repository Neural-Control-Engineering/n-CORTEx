function cfgVars = extractMethodCfg(funcName)
    % Reads the function file
    txt = fileread([funcName, '.m']);

    % Extract lines after 'CFG HEADER' until the first empty line
    expr = '(?<=CFG HEADER\s*\n)((?:[^\n]+\n)+)'; % Captures non-empty lines only
    match = regexp(txt, expr, 'tokens', 'dotall');

    cfgVars = struct(); % Initialize empty struct

    if ~isempty(match)
        cfgBlock = match{1}{1}; % Extract the contiguous block

        % Regular expression to capture variable names and default values
        varExpr = '^\s*([\w\d_]+)\s*=\s*.*?;\s*% default = ([^\n]+)'; 
        vars = regexp(cfgBlock, varExpr, 'tokens', 'lineanchors');

        % Store results in struct
        for i = 1:length(vars)
            varName = vars{i}{1}; % Variable name
            defaultValue = vars{i}{2}; % Default value

            % Convert to numeric if possible
            numValue = str2num(defaultValue); %#ok<ST2NM>
            if isempty(numValue)
                cfgVars.(varName) = defaultValue; % Keep as string if not numeric
            else
                cfgVars.(varName) = numValue; % Store as numeric if conversion works
            end
        end
    end
end
