function ctx = initPIEZO(ctx)
    modality = 'piezo';
    % append PIEZO Panel handle to ctx session
    ctx.(modality).type = {'label','panel'};
    ctx.(modality).label.value = '';
    ctx.(modality).label.order = ctxInitCfg.(modality).labelOrder;
end