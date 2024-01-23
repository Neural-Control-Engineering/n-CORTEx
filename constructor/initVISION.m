function ctx = initVISION(ctx)
    modality = 'vision';
    % append VISION Panel handle to ctx session
    ctx.(modality).type = {'label','panel'};
    ctx.(modality).label.value = '';
    ctx.(modality).label.order = ctxInitCfg.(modality).labelOrder;
end