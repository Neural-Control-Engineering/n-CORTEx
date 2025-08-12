function nexUpdate_dfID(src, event, nexon, nexObj)
    dfID = string(src.Value);
    try
        nexObj.dfID = dfID;
        try % apply to dfID_source (new)
            nexObj.dfID_source = dfID;      
        catch e            
        end
        nexObj.updateScope(nexon);
        nex_updateChildren(nexon, nexObj);
    catch e
        disp(getReport(e));
    end
end