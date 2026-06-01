function [idx_ax, axProps] =  nexOp_row2struct_findIndex(row, varNames, S_ax)
    % create a 1-row table from the input row using provided variable names
    T_row = array2table(row, 'VariableNames', matlab.lang.makeValidName(varNames));
    % table(row, 'VariableNames',varNames)    
    fields_S = fieldnames(S_ax);
    idx_ax = [];
    axProps = [];
    for i = 1:length(fields_S)
        field = fields_S{i};
        val = T_row.(field);
        idx_ax = [idx_ax, find(ismember(S_ax.(field), val))];
        axProps = [axProps, field];
    end    
end