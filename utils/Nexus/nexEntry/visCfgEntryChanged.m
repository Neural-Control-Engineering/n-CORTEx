function visCfgEntryChanged(nexon, nexObj, nexPanel, entryfield, args)
    % recover plotObjs visualization parameters and use the associated
    % visualization method to redraw the plot

    % Update args to be passed into a given method
    value = nexPanel.editFields.(entryfield).uiField.Value;
    % nexPanel.entryParams.editFields.(entryfield) = value;
    nexObj.visCfg.entryParams.(entryfield) = value;
    % nexObjParent = nexObj.Parent;
    % nexObjParent.visCfg.visFcn(nexon, nexObjParent, nexObj, visArgs);
    try
        if nexObj.isStatic % if object is not self-animated - run the visFcn to update the plot
            visArgs = nexObj.visCfg.entryParams;
            nexObj.visCfg.visFcn(nexon, nexObj, visArgs);
        else
            visArgs = nexObj.visCfg.entryParams;
            nexObj.visCfg.visFcn(nexon, nexObj, visArgs);
        end
    catch
            visArgs = nexObj.visCfg.entryParams;
            try
                nexObj.visCfg.visFcn(nexon, nexObj, visArgs);
            catch
                nexObj.visCfg.visFcn(nexObj, visArgs);
            end
    end
    
end