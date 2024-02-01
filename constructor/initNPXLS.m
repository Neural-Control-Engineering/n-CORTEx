function ctx = initNPXLS(ctx, ctxInitCfg)
    modality = 'npxls';
    % append NPXLS Panel handle to ctx session
    ctx.(modality).type = {'label','panel'};
    ctx.(modality).label.value = '';
    

end