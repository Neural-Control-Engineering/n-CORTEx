function nexAnalysis_scaleAnalysis(nexon, nexObjID, analysisFcn, analysisArgs, dfID_source, dfID_target, mask)
    % apply analysis fcn to all rows of a DTS column indicated by dfID
    dtsRows = height(nexon.console.BASE.DTS); % visit each row
    rowStart=1;
    % minLength to truncate long recordings if necessary
    % minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID),"UniformOutput",true);
    % minLength(minLength==0) = [];
    % minLength = min(minLength);
    % fcnName = func2str(fcn);
    if isempty(dfID_target)
        % drop 'df' tag
        nexObjID = strrep("_df","");
        dfID_target = sprintf("%s--%s", nexObjID, func2str(analysisFcn));        
    end
    % for each row in the DTS
    for i = rowStart:dtsRows
        disp(i)        
        % read source data
        DF_in = dtsIO_readDF(nexon,dfID_source,i);      
        DF_out_pre = dtsIO_readDF(nexon,dfID_target,i);
        if isfield(DF_out_pre,"args")
            argsMatch = compareArgs(analysisArgs,DF_out_pre.args);
        else
            argsMatch=0;
        end
        if argsMatch % already complete; don't redo
            continue
        end
        % process source data
        if ~isempty(DF_in)      
            try
                DF_out = analysisFcn(DF_in,analysisArgs);      
            catch e
                disp(getReport(e));
                continue
            end
        else
            DF_out = [];
        end        
        % write analyzed data to target
        dtsIO_writeDF(nexon, DF_out, dfID_target, i);        
    end
    % assign to new column with custom dfID
    fprintf("Analysis Complete: %s", func2str(analysisFcn));
end