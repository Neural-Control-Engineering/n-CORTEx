function dtsIO_writeDF(nexon, DF, DFID, dtsIdx)
    % general purpose data-frame writing from nexus datastore
    % classify input DF
    if isstruct(DF)
        dfType = 'DF';
    else
        dfType = 'df';
    end
    % alternate storage method
    switch dfType
        case 'DF'
            writeDF(nexon, DFID, DF, dtsIdx);
        case 'df'
            writeDataframe(nexon, dfColName, DF, dtsIdx);
    end
end