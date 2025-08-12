function writeDF(nexon, dfID, DF, dtsIdx)    
    % supervenes writeDf; write DF and its fields to respective DTS
    % columns; stores compArgs as the params used to derive the dataframe
    DF_fields = fieldnames(DF);
    for i=1:length(DF_fields)
        dfField = DF_fields{i};        
        fieldVal = DF.(dfField);
        if strcmp(dfField,"ax")
            % recurse into subfields
            writeDF(nexon, dfID, fieldVal, dtsIdx);
            continue % to next dfField
        else
            colTag = sprintf("%s_%s",dfID,dfField);
            writeDataframe(nexon,colTag,fieldVal,dtsIdx);
        end                     
    end
end