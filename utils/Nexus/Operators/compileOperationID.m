function opID = compileOperationID(nexObj)
    if isprop(nexObj,"opCfg")
        % Base case
        opFcnName = rmExtension(func2str(nexObj.opCfg.opFcn));
        opID = sprintf("%s--%s",nexObj.classID, strrep(opFcnName,"_","-"));
        % recurse to parent operation
        opID = sprintf("%s_%s",  compileOperationID(nexObj.Parent), opID);
    else
        opID = "";        
    end    
end