function T3 = mergeTall_vertical(T1, T2)
    t1Vars = convertCharsToStrings(T1.Properties.VariableNames);
    t2Vars = convertCharsToStrings(T2.Properties.VariableNames);
    allVars = unique([t1Vars, t2Vars]);
    for i = 1:length(allVars)
        varName = allVars(i);
        if ~ismember(varName,t1Vars)
            switch(gather(classUnderlying(T2.(varName))))
                case 'double'
                    T1.(varName) = nan.*T1.trialNumber;
                case 'cell'
                    % T1.(varName) = num2cell(nan.*T1.trialNum);
                    T1.(varName) = arrayfun(@(x) {x}, nan.*T1.trialNumber, "UniformOutput", false);
                    % T1.(varName) = (nan.*T1.trialNum);
                case 'string'
            end
        end
        if ~ismember(varName,t2Vars)
            switch(gather(classUnderlying(T1.(varName))))
                case 'double'
                    T2.(varName) = nan.*T2.trialNumber;
                case 'cell'
                    % T2.(varName) = num2cell(nan.*T2.trialNum);
                    T2.(varName) = arrayfun(@(x) {x}, nan.*T2.trialNumber, "UniformOutput", false);
                    % T2.(varName) = (nan.*T2.trialNum);
                case 'string'
            end
        end
    end
    % T3 = [T1; T2];
    success = 0;
    while ~success
        try
            T3 = [T1; T2];
            success = 1;
        catch e % CASE: match double arrays to cell arrays before concatenation until all variables are OK
            if strcmp(e.identifier,'MATLAB:table:vertcat:VertcatCellAndNonCell')
                pattern = "Unable to concatenate the table variable '(\w+)'";
                matches = regexp(e.message, pattern, 'tokens');
                keyVar = convertCharsToStrings(matches{1});            
                t1Type = class(T1.(keyVar));
                t2Type = class(T2.(keyVar));
                if strcmp(t1Type,"double")
                    T1.(keyVar) = num2cell(T1.(keyVar));
                end
                if strcmp(t2Type, "double")
                    T2.(keyVar) = num2cell(T2.(keyVar));
                end
                try
                    T3 = [T1; T2];
                    success = 1;
                catch e
                    disp(e);
                end
            end        
        end
    end
end