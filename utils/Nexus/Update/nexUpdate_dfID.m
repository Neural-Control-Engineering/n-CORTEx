function nexUpdate_dfID(src, event, nexon, nexObj)
    dfID = string(src.Value);
    try
        nexObj.dfID = dfID;
        try
            nexObj.dfID_source = dfID;        
        end
        nexObj.updateScope(nexon);
        nex_updateChildren(nexon, nexObj);
    catch e
        disp(getReport(e));
    end
end