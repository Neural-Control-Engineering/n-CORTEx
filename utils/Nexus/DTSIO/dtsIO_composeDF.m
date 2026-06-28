function DF = dtsIO_composeDF(DTS, DFID, dtsIdx, ptr)
    if nargin < 4, ptr = []; end
    % Disk-backed path: manifest has h5_path column — delegate to HDF5 reader.
    if ismember('h5_path', DTS.Properties.VariableNames)
        DF = dtsIO_readHDF5(DTS, DFID, dtsIdx, ptr);
        return;
    end
    % ptr is not applied to in-memory DTS (no hyperslab concept for arrays in RAM).

    axisKeyWords=["f";"t";"chans";"factor";"dropout";"latent";"peak";"param";"unit";"wf";"measure"];
    tableVars = convertCharsToStrings(DTS.Properties.VariableNames);
    % drop suffixes (for var-matching)
    tableVars_dfID = arrayfun(@(tVar) split(tVar,"_"), tableVars, "UniformOutput", false);
    tableVars_dfID = cellfun(@(tVar) tVar(1:end-1), tableVars_dfID, "UniformOutput", false);
    tableVars_dfID = cellfun(@(tVar) strjoin(tVar,"_"), tableVars_dfID, "UniformOutput", true);
    % idx_matchingVars = contains(tableVars,DFID);
    idx_matchingVars = ismember(tableVars_dfID,DFID);
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
                elseif strcmp(subField,"args")
                    DF.args = df_var; 
                end
            catch
                continue
            end
        end
    end
end