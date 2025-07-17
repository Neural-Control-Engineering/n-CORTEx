function nexUpdate_spectroGraph_specs(nexObj)
    % update DF
    nexObj.DF = nexObj.Parent.DF_postOp;    
    % operate (if applicable)
    % propagate to postOp from parent
    if ~isempty(fieldnames(nexObj.opCfg))
    else
        nexObj.DF_postOp = nexObj.DF; 
    end
    % call visualization
    visArgs = nexObj.visCfg.entryParams;
    nexObj.visCfg.visFcn(nexObj, visArgs);

end