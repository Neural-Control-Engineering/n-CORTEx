function bpFigure =  nexPlot_bandPool(nexon, spectroGram, bandPool)
    df = bandPool.dataFrame;        
    evDf = bandPool.evDataFrame;
    b = bandPool.b;
    evs = bandPool.evs;
    t = bandPool.t;
    
    bpFigure.fh = uifigure("Position",[100,1260,500,900],"Color",[0,0,0]);       
    bandPool.UserData.horizonButton = uibutton(bpFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)switchHorizonMode(nexon, spectroGram, bandPool),"Position",[5,865,25,25],"Text",""); % next    
    bandPool.UserData.horizonButton.UserData.state=0;
    bpFigure.panel1.ph = uipanel(bpFigure.fh,"Position",[5,5,490,850],"BackgroundColor",[0,0,0]);    
    numTraces = size(b,1) + size(evs,1);
    traceNames = [evs; b];
    bandPool.UserData.traceNames = traceNames;
    BP = [evDf; df]; % concatenate events and band pool
    bpFigure.panel1.tiles.t = tiledlayout(bpFigure.panel1.ph,numTraces,1,"TileSpacing","tight");    
    for i = 1:numTraces       
        % tileID = sprintf("%s",i);
        tileID = traceNames(i);
        bpFigure.panel1.tiles.Axes.(tileID) = nexttile(bpFigure.panel1.tiles.t);        
        % traceColor = sprintf("#%s",regMap(regMap.channel==i,:).color{1});
        traceName = traceNames(i);
        switch spectroGram.freqResponse
            case "mag"
                plot(bpFigure.panel1.tiles.Axes.(tileID), t, squeeze(10*log10(BP(1,i,:))));
            case "phase"
                plot(bpFigure.panel1.tiles.Axes.(tileID), t, squeeze(angle(BP(1,i,:))));
        end            
        bpFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", traceName);                       
        colorAx_green(bpFigure.panel1.tiles.Axes.(tileID));            
    end    
end