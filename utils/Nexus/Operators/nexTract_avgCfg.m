function avgCfg = nexTract_avgCfg(nexon)
    avgCfg_sel = nexon.console.BASE.controlPanel.averagingSelection.selections;
    avgCfg_keys = nexon.console.BASE.controlPanel.averagingSelection.selKeys;
    avgCfg = nex_structfun2(@(cfgSel, cfgKey) cfgKey(cfgSel), avgCfg_sel, avgCfg_keys);
end