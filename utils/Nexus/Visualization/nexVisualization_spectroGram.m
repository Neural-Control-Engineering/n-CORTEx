function nexVisualization_spectroGram(nexObj, args)

    % CFG HEADER
    chanSel = args.chanSel; % default = 1
    fRange_start = args.fRange_start; % default = 1
    fRange_end = args.fRange_end; % default = 50
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5    

    f = nexObj.DF_postOp.ax.f;    
    if ~isempty(f); fCond = (f>fRange_start & f<fRange_end); end % select frequencies   
    t = nexObj.DF_postOp.ax.t;            
    
    % df = spectroGram.Parent.dataFrame;
    df = nexObj.DF_postOp.df;
    % df = df(chanSel, fCond);    
    % disp(size(df));
    if max(size(size(df))) == 3
        % disp(df)
        df = df(chanSel,fCond,:);
        if ~isreal(df)
            switch nexObj.Origin.freqResponseType
                case "magnitude"
                    df = 10*log10(abs(df));
                case "phase"
                    df = angle(df);
            end
        end
        if ~isempty(df); nexObj.Figure.panel1.tiles.Axes.spectroGram.CData = squeeze(df); end
    else
        df = df(chanSel, fCond);  
        if ~isreal(df)
            switch nexObj.Origin.freqResponseType
                case "magnitude"
                    df = 10*log10(abs(df));
                case "phase"
                    df = angle(df);
            end
        end
        if ~isempty(df); nexObj.Figure.panel1.tiles.Axes.spectroGram.CData = (df(chanSel,fCond)); end
    end
    nexObj.Figure.panel1.tiles.Axes.spectroGram.Parent.CLim = [cLim_low, cLim_high];
    if ~isempty(f); nexObj.Figure.panel1.tiles.Axes.spectroGram.YData=f(fCond); end
    if ~isempty(t); nexObj.Figure.panel1.tiles.Axes.spectroGram.XData=t; end
    % xline at parent channelgram timeframe
    tIdx = nexObj.Parent.frameNum / nexObj.Parent.opCfg.entryParams.Fs - nexObj.Parent.preBufferLen;
    % nexUpdate_moveSpgXLine(nexon, spectroGram, tIdx);
    % xline event check
    % xline(spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.Parent,tIdx,"Color",nexon.settings.Colors.cyberGreen);

    

end