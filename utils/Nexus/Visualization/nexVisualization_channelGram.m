function nexVisualization_channelGram(nexon, channelGram, args)

    % CFG HEADER    
    fRange_start = args.fRange_start; % default = 1
    fRange_end = args.fRange_end; % default = 50
    cLim_low = args.cLim_low; % default = -11.5
    cLim_high = args.cLim_high; % default = -9.5
    zLim_low = args.zLim_low; % default = -13
    zLim_high = args.zLim_high; % default = -7


    ax = channelGram.DF_postOp.ax;
    % frameIdx = channelGram.frameBuffer.frameIds(channelGram.frameBuffer.)
    df = channelGram.DF_postOp.df(:,:,channelGram.frameBuffer.frameIds==channelGram.frameNum);
    f = ax.f;
    fCond = (f>fRange_start & f<fRange_end); % select frequencies   
    fCond_2 =[1:size(df,2)];
    if length(fCond_2) < length(fCond)
        fCond = fCond_2;    
    end
    % fCond = min([fCond,fRange]);
    df = df(:,fCond); % index select frequencies 
    % tic
    f = f(fCond);
    chans = [1:size(df,1)];
    channelGram.Figure.panel1.tiles.Axes.channelGram.YData = gather([1:size(df,1)]);
    channelGram.Figure.panel1.tiles.Axes.channelGram.XData = gather(f);
    channelGram.Figure.panel1.tiles.Axes.channelGram.ZData = gather(df);
    channelGram.Figure.panel1.tiles.Axes.channelGram.CData = gather(df);
    % toc
    % set ax Lims
    Zmax = max(max(df));
    Zmin = min(min(df));
    % channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.ZLim = [Zmin*1.05,Zmax*0.9];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.CLim=[cLim_low, cLim_high];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.ZLim = [zLim_low, zLim_high];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.XLim = [f(1),f(end)];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.YLim = [chans(1),chans(end)];
    %% plot Fooof reconstruction
    % channelGram.chgFigure.panel1.tiles.Axes.fooof = nexttile(channelGram.chgFigure.panel1.tiles.t);
    % fooofPredictions = extractRT_fooof(channelGram.rtSpec,df);
    % channelGram.chgFigure.panel1.tiles.Axes.fooof = plotFooofContours(channelGram.chgFigure.panel1.tiles.Axes.fooof, f_psd, fooofPredictions);
    % figure color mapping
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(channelGram.Figure.fh,CT);
    % channelGram plot
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.Color=[0,0,0];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.Color=[0.24,0.94,0.46];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.GridColor=[0.24,0.94,0.46];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.XColor=[0.24,0.94,0.46];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.YColor=[0.24,0.94,0.46];
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.ZColor=[0.24,0.94,0.46];
    % title header
    t_frame = channelGram.frameNum / channelGram.opCfg.entryParams.Fs - channelGram.preBufferLen;
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.String=(sprintf("%0f (s)",t_frame));        
end

% edit nexObj_rtChannelGram.m; edit nexObj_rtPixelGram.m