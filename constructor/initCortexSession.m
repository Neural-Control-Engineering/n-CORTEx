function ctx = initCortexSession(ctxInitCfg)
    

    % DATE HANDLE
    ctx.date.type = {'label'};

    % SUBJECT HANDLE
    ctx.subject.type = {'label'};
    
    % INIT PANELS
    cortexPanels = upper(fieldnames(ctxInitCfg));
    for i = 1:length(cortexPanels)        
        panel = cortexPanels{i};
        if ctxInitCfg.(lower(panel)).EN
            initHndl = str2func(sprintf("init%s",panel));
            ctx = initHndl(ctx, ctxInitCfg);
        end
    end
   
end