function DF = dtsIO_readDF(nexon, DFID, dtsIdx)
    % general purpose data-frame reading from nexus datastore
    % classify input DF
    % find all columns associated with DFID
    % dfFields = dtsIO_listVarsContaining(nexon.console.BASE.DTS, DFID);
    DF = dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx);    
end