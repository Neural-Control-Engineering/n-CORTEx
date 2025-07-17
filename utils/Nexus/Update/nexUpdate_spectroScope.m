function nexUpdate_spectroScope(nexObj)
    % retrieve precomputed spectral parameters (if available)
    % otherwise generate a new DF_specs
    % visualize update

    % Retrieval
    try % RECOVERY
        try
            nexObj.DF_postOp = dtsIO_readDF(nexObj.nexon, nexObj.dfID_target,[]);
        catch
            nexObj.DF_postOp = retrieveFrameBuffer(nexObj);
        end
    catch % COMPUTE NEW
        compArgs=nexObj.compCfg.entryParams;
        nexObj.compCfg.fcn(nexObj,compArgs);
    end

    % Formatting
    % df_pre = nexObj.DF.df;
    % fRange = [min((nexObj.DF.ax.f)), max(nexObj.DF.ax.f)];
    DF_form = formatSpecs(nexObj.DF_postOp,"timeFrequency", nexObj.map_specs.Map);
    % DF_form.mask_specs = generateSpecsMask(DF_form);    

    DF_pooled = DF_form;
    [DF_pooled.df, binIDs_chans, binTicks_chans] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_chans,1, DF_form.ax.chans), DF_pooled.df,"UniformOutput",false);
    [DF_pooled.df, binIDs_freqs, binTicks_freqs] = structfun(@(df) nexAnalysis_averagePool(df, nexObj.pMap_freqs,2, DF_form.ax.f), DF_pooled.df,"UniformOutput",false);
    % need to omit nans
    DF_pooled.ax.chans=binTicks_chans.CF';
    DF_pooled.ax.f=binTicks_freqs.CF';
    DF_pooled.mask_specs = generateSpecsMask(DF_pooled);    
    nexObj.DF_postOp = DF_pooled;    

    % Visualization
    visArgs = nexObj.visCfg.entryParams;
    nexObj.visCfg.visFcn(nexObj, visArgs)

    % update Children
    nex_updateChildren(nexObj.nexon, nexObj);

end