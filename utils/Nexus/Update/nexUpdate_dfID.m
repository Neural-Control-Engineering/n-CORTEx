function nexUpdate_dfID(src, event, nexon, nexObj)
    dfID = string(src.Value);
    try
        nexObj.dfID = dfID;
        nexObj.updateScope(nexon);
        nex_updateChildren(nexon, nexObj);
    catch e
        disp(getReport(e));
    end
end