function nexUpdate_spectroGraph(nexObj)
    % update DF
    nexObj.DF = nexObj.Parent.DF_postOp;
    % call visualization
    visArgs = nexObj.visCfg.entryParams;
    try
        nexObj.visCfg.visFcn(nexObj, visArgs);
    catch e
        disp(getReport(e));
    end
end