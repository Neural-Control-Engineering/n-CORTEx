function var = dtsIO_readVar(dataObj, varID, idxSel)
    % DF/nexon sensitive
    switch class(dataObj)
        case 'Nexon'
            try
                var = dataObj.console.BASE.DTS.(varID);
            catch
                keyboard
            end
        case 'table'
            var = dataObj.(varID);
    end    
    var = var(idxSel);
end