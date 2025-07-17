function DF = dtsIO_composeDF(DTS, DFID, dtsIdx)
    axisKeyWords=["f";"t";"chans"];
    tableVars = convertCharsToStrings(DTS.Properties.VariableNames);
    idx_matchingVars = contains(tableVars,DFID);
    vars = tableVars(idx_matchingVars);
    DF = struct;
    for i = 1:length(vars)
        var = vars(i);
        % subField = strrep(var,strcat(DFID),"");
        subField = split(var,"_");
        subField = subField(end);
        % subField = strrep(subField,"_","");
        % type sensitive here...
        df_var = DTS.(var){dtsIdx};
        if any(contains(axisKeyWords, subField))
            DF.ax.(subField) = df_var;
        elseif ~strcmp(subField,"")
            DF.(subField) = df_var;
        else
            DF.df = df_var;
        end              
    end
end