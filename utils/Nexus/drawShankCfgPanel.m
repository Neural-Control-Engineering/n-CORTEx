function configPanel = drawShankCfgPanel(nexon, shank)
    % configuration panel to navigate spectral bands, configure PSD
    % calculations    
    valueChangedFcn = str2func("shankConfigEntryChanged");
    configParams = nexon.console.BASE.params.psdCfg;
    bandNames = convertCharsToStrings(fieldnames(nexon.console.BASE.params.bands));
    configParams.bandSel = bandNames;
    configPanel = nexObj_entryPanel(nexon,configParams,valueChangedFcn);        
end