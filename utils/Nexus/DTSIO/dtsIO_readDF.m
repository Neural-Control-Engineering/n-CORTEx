function DF = dtsIO_readDF(nexon, DFID, dtsIdx)
    % general purpose data-frame reading from nexus datastore
    % classify input DF
    % find all columns associated with DFID
    % dfFields = dtsIO_listVarsContaining(nexon.console.BASE.DTS, DFID);
    if isscalar(dtsIdx)
        DF = dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx);    
    elseif isempty(dtsIdx)
        dtsIdx = nex_getRouterIdx(nexon);
        DF = dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx);    
    else
        DF = {};        
        for i = 1:length(dtsIdx)
            dtsIdx_i = dtsIdx(i);
            DF_i = dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx_i);
            DF = [DF; DF_i];
        end
    end
end