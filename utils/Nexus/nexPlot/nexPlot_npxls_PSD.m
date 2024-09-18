function nexPlot_npxls_PSD(nexon)
    lfp = nexon.console.npxlsLFP.UserData.lfp;
    psdCfg = nexon.console.base.UserData.params.psdCfg;    
    bands = nexon.console.base.UserData.params.bands;
    [PSD, f_psd] = computeSpectralDensity()
    nexon.console.npxlsLFP.UserData.PSD = PSD;
    nexon.console.npxlsLFP.UserData.f_PSD = f_psd;
    [PSD_bands, b] = binNeuralBands(bands,PSD);
    bandSel = nexon.console.npxlsLFP.UserData.bandSel;
    bandIdx = find(strcmp(b,bandSel));
    dataFrame = squeeze(PSD_bands(:,:,bandIdx));
    nexon.console.npxlsLFP.UserData.dataFrame = dataFrame;
    updateNpxlsPanel(nexon,"dataFrame");
end