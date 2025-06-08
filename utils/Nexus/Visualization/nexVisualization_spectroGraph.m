function nexVisualization_spectroGraph(nexObj, args)

    % CFG HEADER
    chanSel = args.chanSel; % default = 1
    freqSel = args.freqSel; % default = 1

    % CASES:
    % 1) single trial
    % 2) avg but only for current phase
    % 3) avg for multiple phases
    DF = nexObj.DF;
    df_slice = DF.df(chanSel, freqSel,:);
    % plot timecourse (with sem shading if applicable)
    % title handling with poolMap from origin
    % chanIdx = nexObj.poolMap_chans.getIndex(chanSel);
    regionName = nexObj.poolMap_chans.getBinID(chanSel);
    bandName = nexObj.poolMap_freqs.getBinID(freqSel);
    title(sprintf("%s--%s",regionName,bandName));
    
    nexObj.Figure.panel1.tiles.Axes.spgph.YData = dfSlice;
    % nexUpdate_moveSpgXLine(nexon, spectroGram, tIdx);

end