function dtsIO_writeDF(nexon, DF, DFID, dtsIdx)
    % general purpose data-frame writing from nexus datastore
    % classify input DF
    if isstruct(DF)
        dfType = 'DF';
    else
        dfType = 'df';
    end
    % classify index type
    if isstruct(dtsIdx)
        % search logic and fieldname logic
        rowIdx = nex_searchRowAddress(nexon.console.BASE.DTS, dtsIdx);
        if isempty(rowIdx)
            % start a new row (with address coordinates (e.g. sl, trialNum,
            % etc.))
            % for i = 1:length(addressFields)
            %     writeDataFrame(nexon, dfColName, df, rowIdx);
            % end
            rowStruct=dtsIdx;            
            rowStruct.(DFID)=DF;
            row_dts = dtsIO_compileDTS(rowStruct,[]);            
            % writeDataFrame(nexon, dfColName, df, rowIdx);
            nexon.appendToDTS(row_dts);
        else
            % alternate storage method
            switch dfType
                case 'DF'
                    writeDF(nexon, DFID, DF, rowIdx);
                case 'df'
                    writeDataframe(nexon, dfColName, DF, rowIdx);
            end
        end
        
    else
        % alternate storage method
        switch dfType
            case 'DF'
                writeDF(nexon, DFID, DF, dtsIdx);
            case 'df'
                writeDataframe(nexon, dfColName, DF, dtsIdx);
        end
    end
    
end