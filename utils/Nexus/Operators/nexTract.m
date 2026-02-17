function nexTract(nexon, fcn, dfID, mask)
    % apply analysis fcn to all rows of a DTS column indicated by dfID
    dtsRows = height(nexon.console.BASE.DTS); % visit each row
    % minLength to truncate long recordings if necessary
    minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID),"UniformOutput",true);
    minLength(minLength==0) = [];
    minLength = min(minLength);
    fcnName = func2str(fcn);
    dfID_entry = strrep(dfID,"_df",""); % get rid of df handle
    dfColName = sprintf("%s_%s", dfID_entry, fcnName);

    
    DFOUT = {};
    for i = 1:dtsRows
        disp(i);
        % df = nexon.console.BASE.DTS.(dfID){i};    
        DF_in = dtsIO_readDF(nexon, dfID_entry, i);
        df = DF_in.df;
        if ~isempty(df)
            try
                if size(df,2) > minLength * 1.01
                    DF_in.df = df(:,1:minLength);
                end
                args = extractMethodCfg(fcnName);
                % df_out = fcn(df,args);      
                DF_out = fcn(DF_in, args);
                % DF_out.df=df_out;
            catch e
                disp(getReport(e));
                continue
            end
        else
            % df_out = [];
            % DF_out=[];
            continue
        end
        % writeDf(nexon, dfColName, df_out,i);
        % writeDataframe(nexon, dfColName, df_out,i);
        dtsIO_writeDF(nexon,DF_out,dfColName,i);
        % DFOUT = [DFOUT; df_out];
    end
    % assign to new column with custom dfID
    
end