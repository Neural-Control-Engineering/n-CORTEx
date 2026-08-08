function DF = dtsIO_composeDF(DTS, DFID, dtsIdx, ptr)
    if nargin < 4, ptr = []; end
    % Hybrid DTS: h5_path column may exist but some rows are still in memory
    % (h5_path == ""). Check the specific row, not just the column's presence.
    if ismember('h5_path', DTS.Properties.VariableNames)
        h5path = string(DTS.h5_path(dtsIdx));
        if strlength(h5path) > 0
            DF = dtsIO_readHDF5(DTS, DFID, dtsIdx, ptr);
            return;
        end
        % else: in-memory row inside a hybrid DTS — fall through to column read
    end
    % ptr is not applied to in-memory DTS (no hyperslab concept for arrays in RAM).

    % Resolve the dfID to its columns + the base to split on — the single source
    % of truth shared with dtsIO_readDF and the launcher presence check.
    [vars, baseDFID] = dtsIO_resolveDFID(DTS, DFID);
    if isempty(vars)
        DF = [];   % explicit not-found (was a silent fieldless struct)
        return;
    end

    axisKeyWords = nex_axisKeyWords();
    DF = struct;
    for i = 1:numel(vars)
        var      = char(vars(i));
        subField = split(string(var), sprintf("%s_", baseDFID));
        if isscalar(subField)
            % bare column named exactly the base — the df stored directly
            switch class(DTS.(var))
                case "cell"
                    DF.df = DTS.(var){dtsIdx};
                otherwise
                    DF.df = DTS.(var)(dtsIdx);
            end
            DF.ax = nexOp_generateAx(DF);
        else
            try
                stub   = subField(2);            % the <stub> after "base_"
                df_var = DTS.(var){dtsIdx};
                if any(contains(axisKeyWords, stub))
                    DF.ax.(char(stub)) = df_var;
                elseif strcmp(stub, "df")
                    DF.df = df_var;
                elseif strcmp(stub, "args")
                    DF.args = df_var;
                end
            catch
                continue
            end
        end
    end
end
