function DF = dtsIO_composeDF(DTS, DFID, dtsIdx)
    axisKeyWords=["f";"t";"chans"];
    tableVars = convertCharsToStrings(DTS.Properties.VariableNames);
    idx_matchingVars = contains(tableVars,DFID);
    vars = tableVars(idx_matchingVars);
    DF = struct;
    for i = 1:length(vars)
        var = vars(i);
        % subField = strrep(var,strcat(DFID),"");
        % subField = split(var,"_");
        subField = split(var,sprintf("%s_",DFID));
        if strcmp(var, subField)
            switch class(DTS.(var))
                case "cell"
                    DF.df=DTS.(var){dtsIdx};
                otherwise
                    DF.df = DTS.(var)(dtsIdx);
            end
            DF.ax = nexOp_generateAx(DF);
        else
            try
                subField = subField(2); % take very next sub-tag
                % subField = strrep(subField,"_","");
                % type sensitive here...
                df_var = DTS.(var){dtsIdx};
                % df_var = DTS.(var)(dtsIdx);
                if any(contains(axisKeyWords, subField))
                    DF.ax.(subField) = df_var;
                % elseif ~strcmp(subField,"")
                %     DF.(subField) = df_var;
                elseif strcmp(subField,"df")
                    DF.df = df_var; 
                end
            catch
                continue
            end
        end
    end
end