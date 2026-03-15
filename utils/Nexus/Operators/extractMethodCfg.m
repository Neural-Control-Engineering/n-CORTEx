function cfgVars = extractMethodCfg(funcName)
    % Reads the function file.
    % Supports ClassName.methodName — reads the class file and isolates
    % the target method's block before parsing the CFG HEADER.
    if contains(funcName, '.')
        parts  = strsplit(funcName, '.');
        className  = parts{1};
        methodName = parts{end};
        classFile  = which([className, '.m']);
        if isempty(classFile), classFile = [className, '.m']; end
        fullTxt = fileread(classFile);
        % Trim to the start of the target method so the CFG HEADER search
        % finds only this method's header, not another method's.
        startIdx = regexp(fullTxt, sprintf('\\bfunction\\b[^\\n]*\\b%s\\b', methodName), 'start', 'once');
        if isempty(startIdx)
            cfgVars = struct();
            return;
        end
        txt = fullTxt(startIdx:end);
    else
        txt = fileread([funcName, '.m']);
    end

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

            % Convert to numeric if possible; detect quoted string literals
            numValue = str2num(defaultValue); %#ok<ST2NM>
            if ~isempty(numValue)
                cfgVars.(varName) = numValue;
            else
                dv = strtrim(defaultValue);
                if (startsWith(dv, '"') && endsWith(dv, '"')) || ...
                   (startsWith(dv, "'") && endsWith(dv, "'"))
                    % Quoted string literal — strip quotes, return as MATLAB string
                    % so breakoutCfgFields_v4 creates a uieditfield("text") for it
                    cfgVars.(varName) = string(dv(2:end-1));
                else
                    cfgVars.(varName) = defaultValue; % raw char fallback
                end
            end
        end
    end
end
