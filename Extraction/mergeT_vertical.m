function M = mergeT_vertical(T1, T2)
    T1Vars = T1.Properties.VariableNames;
    sizeT1 = size(T1);
    T2Vars = T2.Properties.VariableNames;
    sizeT2 = size(T2);
    allVars = [T1Vars T2Vars];
    for i = 1:length(allVars)
        checkVar = allVars{i};
        % if all(~contains(T1Vars,checkVar))
        if all(~ismember(T1Vars,checkVar))            
            T1.(checkVar) = cell(sizeT1(1),1);        
            % if iscell(T2.(checkVar))
            %     T1.(checkVar) = cell(sizeT1(1),1);        
            % else
            %     T1.(checkVar) = nan(sizeT1(1),1);        
            % end
        end
        if all(~ismember(T2Vars,checkVar))
            T2.(checkVar) = cell(sizeT2(1),1);        
            % if iscell(T1.(checkVar))
            %     T2.(checkVar) = cell(sizeT2(1),1);        
            % else
            %     T2.(checkVar) = nan(sizeT2(1),1);        
            % end
        end
    end
    success = 0;
    while ~success
        try
            M = [T1; T2];
            success = 1;
        catch e % CASE: match double arrays to cell arrays before concatenation until all variables are OK
            disp(e);
            if strcmp(e.identifier,'MATLAB:table:vertcat:VertcatCellAndNonCell')
                pattern = "Unable to concatenate the table variable '(\w+)'";
                matches = regexp(e.message, pattern, 'tokens');
                keyVar = convertCharsToStrings(matches{1});            
                t1Type = class(T1.(keyVar));
                t2Type = class(T2.(keyVar));
                if strcmp(t1Type,"double")
                    T1.(keyVar) = num2cell(T1.(keyVar));
                elseif strcmp(t1Type,"string")
                    T1.(keyVar) = cellstr(T1.(keyCar));
                end
                if strcmp(t2Type, "double")
                    T2.(keyVar) = num2cell(T2.(keyVar));
                end
                try
                    M = [T1; T2];
                    success = 1;
                catch e
                    disp(e);
                end
            end        
        end
    end
end