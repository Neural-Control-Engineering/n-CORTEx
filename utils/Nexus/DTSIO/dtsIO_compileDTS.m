function row_dts = dtsIO_compileDTS(s_dts, preFix)
    % s_dts : struct containing dts column-wise data
    dtsFields = fieldnames(s_dts);
    if isempty(preFix)
        preFix="";
    else
        preFix = strcat(preFix,"_");
    end
    row = [];
    for i = 1:length(dtsFields)
        dtsField = dtsFields{i};        
        dtsColName = sprintf("%s%s",preFix,dtsField);
        dtsVal = s_dts.(dtsField);
        if isstruct(dtsVal)
            row = [row, dtsIO_compileDTS(dtsVal, dtsField)];
        elseif (size(dtsVal,1))>1
            row = [row, table({dtsVal}, 'VariableNames', dtsColName)];
        else
            row = [row, table(dtsVal, 'VariableNames', dtsColName)];
        end
    end
    row_dts = row;
end