function nex_updateChildren(nexon, nexObj)
    nexObjChildrenList = fieldnames(nexObj.Children);
    for i = 1:length(nexObjChildrenList)
        nexObjChildName = nexObjChildrenList{i};
        nexObjChild = nexObj.Children.(nexObjChildName);
        % run update method
        try
            nexObjChild.updateScope(nexon);
        catch e
            disp(getReport(e));
        end
    end
end