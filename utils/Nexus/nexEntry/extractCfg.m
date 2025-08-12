function cfg = extractCfg(Fcn)
    try
        cfg.entryParams = extractMethodCfg(rmExtension(func2str(Fcn)));
    catch e
        disp(getReport(e));
        cfg.entryParams = struct;
        cfg.opFcn=[];
    end
end