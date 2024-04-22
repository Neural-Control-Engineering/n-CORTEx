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
    M = [T1; T2];
end