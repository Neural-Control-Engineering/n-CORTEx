function nexUpdate_opFcn(src, event, nexObj)
    opFcn = string(src.Value);
    try
        nexObj.opCfg.opFcn = str2func(opFcn);
        nexObj.updateScope(nexObj.nexon);
        nex_updateChildren(nexObj.nexon, nexObj);
    catch e
        disp(getReport(e));
    end
end