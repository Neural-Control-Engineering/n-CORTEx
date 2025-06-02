function DF = dtsIO_composeDF(DTS, DFID, dtsIdx)
    tableVars = convertCharsToStrings(DTS.Properties.VariableNames);
    idx_matchingVars = contains(tableVars,DFID);
    vars = tableVars(idx_matchingVars);
    DF = struct;
    for i = 1:length(vars)
        var = vars(i);
        subField = strrep(var,strcat(DFID),"");
        subField = strrep(subField,"_","");
        % type sensitive here...
        df_var = DTS.(var){dtsIdx};
        if ~strcmp(subField,"")
            DF.(subField) = df_var;
        else
            DF.df = df_var;
        end              
    end
end