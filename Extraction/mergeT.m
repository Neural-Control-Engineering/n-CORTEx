function T3 = mergeT(T1, T2)
    T1Vars = T1.Properties.VariableNames;
    sizeT1 = size(T1);
    T2Vars = T2.Properties.VariableNames;
    sizeT2 = size(T2);
    allVars = [T1Vars T2Vars];
    for i = 1:length(allVars)
        checkVar = allVars{i};       
        if all(~ismember(T1Vars,checkVar))            
            class_checkVar = class(T2.(checkVar));
            switch class_checkVar
                case 'string'
                    verifiedColumn = repmat("", height(T1), 1);  % Create a column of "Verified"                    
                    T1 = addvars(T1, verifiedColumn, 'NewVariableNames', checkVar);                    
                case 'double'
                    verifiedColumn = repmat([], height(T1), 1);  % Create a column of "Verified"                    
                    T1 = addvars(T1, verifiedColumn, 'NewVariableNames', checkVar);                    
                otherwise
                    T1.(checkVar) = cell(sizeT1(1),1);                    
            end            
            T1.(checkVar) = cell(sizeT1(1),1);                    
        end
        if all(~ismember(T2Vars,checkVar))
            class_checkVar = class(T1.(checkVar));
            switch class_checkVar
                case 'string'
                    verifiedColumn = repmat("", height(T2), 1);  % Create a column of "Verified"                    
                    T2 = addvars(T2, verifiedColumn, 'NewVariableNames', checkVar);                    
                case 'double'
                    verifiedColumn = repmat(nan, height(T2), 1);  % Create a column of "Verified"                    
                    T2 = addvars(T2, verifiedColumn, 'NewVariableNames', checkVar);                    
                otherwise
                    T2.(checkVar) = cell(sizeT2(1),1);                    
            end            
        end
    end
    T3 = [T1; T2];
end