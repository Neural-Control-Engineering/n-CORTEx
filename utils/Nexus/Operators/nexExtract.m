function nexExtract(nexon, fcn, dfID, mask)
    % apply analysis fcn to all rows of a DTS column indicated by dfID
    dtsRows = height(nexon.console.BASE.DTS); % visit each row
    % minLength to truncate long recordings if necessary
    minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID),"UniformOutput",true);
    minLength(minLength==0) = [];
    minLength = min(minLength);
    fcnName = func2str(fcn);
    dfColName = sprintf("%s_%s", dfID, fcnName);

    
    DFOUT = {};
    for i = 1:dtsRows
        disp(i)
        df = nexon.console.BASE.DTS.(dfID){i};    
        if ~isempty(df)
            if size(df,2) > minLength * 1.01
                df = df(:,1:minLength);
            end
            args = extractMethodCfg(fcnName);
            df_out = fcn(df,args);      
        else
            df_out = [];
        end
        writeDf(nexon, dfColName, df_out,i);
        DFOUT = [DFOUT; df_out];
    end
    % assign to new column with custom dfID
    
end