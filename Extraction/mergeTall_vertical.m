function T3 = mergeTall_vertical(T1, T2)
    t1Vars = convertCharsToStrings(T1.Properties.VariableNames);
    t2Vars = convertCharsToStrings(T2.Properties.VariableNames);
    allVars = unique([t1Vars, t2Vars]);
    for i = 1:length(allVars)
        varName = allVars(i);
        if ~ismember(varName,t1Vars)
            switch(gather(classUnderlying(T2.(varName))))
                case 'double'
                    T1.(varName) = nan.*T1.trialNum;
                case 'cell'
                    % T1.(varName) = num2cell(nan.*T1.trialNum);
                    T1.(varName) = arrayfun(@(x) {x}, nan.*T1.trialNum, "UniformOutput", false);
                    % T1.(varName) = (nan.*T1.trialNum);
                case 'string'
            end
        end
        if ~ismember(varName,t2Vars)
            switch(gather(classUnderlying(T1.(varName))))
                case 'double'
                    T2.(varName) = nan.*T2.trialNum;
                case 'cell'
                    % T2.(varName) = num2cell(nan.*T2.trialNum);
                    T2.(varName) = arrayfun(@(x) {x}, nan.*T2.trialNum, "UniformOutput", false);
                    % T2.(varName) = (nan.*T2.trialNum);
                case 'string'
            end
        end
    end
    T3 = [T1; T2];
end