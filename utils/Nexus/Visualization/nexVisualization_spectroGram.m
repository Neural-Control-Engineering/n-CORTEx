function nexVisualization_spectroGram(nexon, spectroGram, args)

    % CFG HEADER
    chanSel = args.chanSel; % default = 1
    fRange_start = args.fRange_start; % default = 1
    fRange_end = args.fRange_end; % default = 50
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5    

    f = spectroGram.DF_postOp.ax.f;    
    if ~isempty(f); fCond = (f>fRange_start & f<fRange_end); end % select frequencies   
    t = spectroGram.DF_postOp.ax.t;            
    
    % df = spectroGram.Parent.dataFrame;
    df = spectroGram.DF_postOp.df;
    % disp(size(df));
    if max(size(size(df))) == 3
        % disp(df)
        if ~isempty(df); spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.CData = squeeze(df(chanSel,fCond,:)); end
    else
        if ~isempty(df); spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.CData = (df(chanSel,fCond)); end
    end
    spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.Parent.CLim = [cLim_low, cLim_high];
    if ~isempty(f); spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.YData=f(fCond); end
    if ~isempty(t); spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.XData=t; end
    % xline at parent channelgram timeframe
    tIdx = spectroGram.Parent.frameNum / spectroGram.Parent.opCfg.entryParams.Fs - spectroGram.Parent.preBufferLen;
    nexUpdate_moveSpgXLine(nexon, spectroGram, tIdx);
    % xline(spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.Parent,tIdx,"Color",nexon.settings.Colors.cyberGreen);

    

end