function nex_writeFeature(nexObj, args)

    % CFG HEADER
    isWriteToDts = args.isWriteToDts; % default = 1
    isWriteToDataset = args.isWriteToDataset; % default = 0

    % % for each item in the DTS, grab, compute, and write    
    postOpID = sprintf("%s--%s",nexObj.classID, func2str(nexObj.opCfg.opFcn));
    % if  any(ismember(nexObj.nexon.console.BASE.DTS.Properties.VariableNames,sprintf("%s_df",postOpID)))
    %     dtsIdx = nexObj.UserData.sampleNum;
    %     nexObj.DF_postOp.df = grabDataFrame(nexObj.nexon,sprintf("%s_df",postOpID),dtsIdx);
    %     if isempty(nexObj.DF_postOp.df)
    %         return
    %     end
    %     nexObj.DF_postOp.ax.f = grabDataFrame(nexObj.nexon,sprintf("%s_f",postOpID),dtsIdx);
    %     nexObj.DF_postOp.ax.t = grabDataFrame(nexObj.nexon,sprintf("%s_t",postOpID),dtsIdx);
    %     nexObj.DF_postOp.ax.chans = grabDataFrame(nexObj.nexon,sprintf("%s_chans",postOpID),dtsIdx);
    %     isWriteToDts = 0;
    %     disp("data precomputed")
    %     % trim to minLength
    %     minLength = nex_getDfMinLength(nexObj.nexon, sprintf("%s_t",postOpID));
    %     nexObj.DF_postOp.df = nexObj.DF_postOp.df(:,:,1:minLength);
    %     nexObj.DF_postOp.ax.t = nexObj.DF_postOp.ax.t(1:minLength);
    % else
    %     nexObj.DF_postOp = nexObj.compCfg.compFcn(nexObj, nexObj.compCfg.entryParams);
    % end

    nexObj.DF_postOp = nexObj.compCfg.compFcn(nexObj, nexObj.compCfg.entryParams);

    if isWriteToDts
        % postOpID = sprintf("%s--%s",nexObj.classID, func2str(nexObj.opCfg.opFcn));        
        dtsIdx = nexObj.UserData.sampleNum;
        writeDF(nexObj.nexon, postOpID, nexObj.DF_postOp, dtsIdx);
    end

    if isWriteToMemory
        
    end

    % write exports
    if isWriteToDataset
        nexObj.exportCfg.exportFcn(nexObj, nexObj.exportCfg.entryParams);
    end

    % writeFeature for each child (recurse)
    childObjs = fieldnames(nexObj.Children);
    for i = 1:length(childObjs)
        childObj = nexObj.Children.(childObjs{i});
        % confer sample coordinates 
        childObj.UserData.labelKeys = nexObj.UserData.labelKeys;
        childObj.UserData.labelVals = nexObj.UserData.labelVals;
        childObj.UserData.labelIDs = nexObj.UserData.labelIDs;
        childObj.UserData.foldNum = nexObj.UserData.foldNum;
        childObj.UserData.sampleNum = nexObj.UserData.sampleNum;
        % assign new df to child
        childObj.DF = nexObj.DF_postOp;
        writeArgs = extractMethodCfg('nex_writeFeature'); % default yes for now        
        try
            if childObj.isWriteSelected
                nex_writeFeature(childObj, writeArgs);
            end
        catch e
            % disp(getReport(e));
        end
    end

end