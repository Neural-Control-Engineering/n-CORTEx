function nexVisualization_channelGram(nexon, nexObj, args)

    % CFG HEADER    
    fRange_start = args.fRange_start; % default = 1
    fRange_end = args.fRange_end; % default = 50
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5
    zLim_low = args.zLim_low; % default = -13
    zLim_high = args.zLim_high; % default = -7


    ax = nexObj.DF_postOp.ax;
    % frameIdx = nexObj.frameBuffer.frameIds(nexObj.frameBuffer.)
    df = nexObj.DF_postOp.df(:,:,nexObj.frameBuffer.frameIds==nexObj.frameNum);
    f = ax.f;
    fCond = (f>fRange_start & f<fRange_end); % select frequencies   
    fCond_2 =[1:size(df,2)];
    if length(fCond_2) < length(fCond)
        fCond = fCond_2;    
    end
    % fCond = min([fCond,fRange]);
    df = df(:,fCond); % index select frequencies 
    % frequency-response dependent transform
    if ~isreal(df)
        switch nexObj.freqResponseType
            case "magnitude"
                df = 10*log10(abs(df));
            case "phase"
                df = angle(df);
        end
    end
    % tic
    f = f(fCond);
    % apply log to f-axis
    % f = log10(f);
    f=log(f);
    % Generate logarithmically spaced tick positions
    numTicks = 30;
    f_ticks = (logspace(log(f(1)), log(f(end)), numTicks));
    chans = [1:size(df,1)];
    nexObj.Figure.panel1.tiles.Axes.channelGram.YData = gather([1:size(df,1)]);
    nexObj.Figure.panel1.tiles.Axes.channelGram.XData = gather(f);
    nexObj.Figure.panel1.tiles.Axes.channelGram.ZData = gather(df);
    nexObj.Figure.panel1.tiles.Axes.channelGram.CData = gather(df);
    % toc
    % set ax Lims
    Zmax = max(max(df));
    Zmin = min(min(df));
    % nexObj.Figure.panel1.tiles.Axes.nexObj.Parent.ZLim = [Zmin*1.05,Zmax*0.9];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.CLim=[cLim_low, cLim_high];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.ZLim = [zLim_low, zLim_high];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.XLim = [f(1),f(end)];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.XTick = f_ticks;
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.XTickLabel = exp(f_ticks);
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.YLim = [chans(1),chans(end)];
    %% plot Fooof reconstruction
    % nexObj.chgFigure.panel1.tiles.Axes.fooof = nexttile(nexObj.chgFigure.panel1.tiles.t);
    % fooofPredictions = extractRT_fooof(nexObj.rtSpec,df);
    % nexObj.chgFigure.panel1.tiles.Axes.fooof = plotFooofContours(nexObj.chgFigure.panel1.tiles.Axes.fooof, f_psd, fooofPredictions);
    % figure color mapping
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    % nexObj plot
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.Color=[0,0,0];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.Color=[0.24,0.94,0.46];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.GridColor=[0.24,0.94,0.46];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.XColor=[0.24,0.94,0.46];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.YColor=[0.24,0.94,0.46];
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.ZColor=[0.24,0.94,0.46];
    % title header
    t_frame = nexObj.frameNum / nexObj.opCfg.entryParams.Fs - nexObj.preBufferLen;
    nexObj.Figure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.String=(sprintf("%0f (s)",t_frame));        
end

% edit nexObj_rtnexObj.m; edit nexObj_rtPixelGram.m