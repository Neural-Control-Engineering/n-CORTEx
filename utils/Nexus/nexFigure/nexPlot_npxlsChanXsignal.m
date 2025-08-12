function nexPlot_npxlsChanXsignal(nexon, shank, timeCourse)
    sigSel = "stimTrace_lowess_span2";
    chanSel = 1;
    sigData = downsample(grabDataFrame(nexon,sigSel),2);
    sigData = [ones(1250,1)*mean(sigData(1:500)); sigData; ones(1250,1)*mean(sigData(end-100:end))];
    lfp = grabDataFrame(nexon,"lfp");
    PSD_bands = timeCourse.UserData.PSD_bands;
    b = timeCourse.UserData.b;
    bands = nexon.console.BASE.params.bands;
    bandNames = fieldnames(bands);
    t_stim = [1:size(sigData,1)] ./ 500 - 3.5;
    t_lfp = [1:size(lfp,2)] ./ 500 - 3.5;
    t_band = [1:size(PSD_bands,2)] ./500 - 3.5;
    % figure; plot(t,sigData)
    numTiles = 7;
    signalTc.fh = uifigure("Position",[100,1260,500,800],"Color",[0,0,0]);   
    signalTc.ph = uipanel(signalTc.fh,"Position",[5,5,490,790],"BackgroundColor",[0,0,0]);
    signalTc.tiles.t = tiledlayout(signalTc.ph,numTiles,1,"TileSpacing","tight");    
    signalTc.tiles.Axes.tile1 = nexttile(signalTc.tiles.t);
    plot(signalTc.tiles.Axes.tile1,t_stim, sigData);
    colorAx_green(signalTc.tiles.Axes.tile1);        
    % plot LFP bands
    bCounter = 1;
    for i = 2:numTiles
        tileID = sprintf("tile%d",i);
        signalTc.tiles.Axes.(tileID) = nexttile(signalTc.tiles.t);
        if i == 2
            plot(signalTc.tiles.Axes.(tileID),t_lfp, lfp(chanSel,:));
        else
            plot(signalTc.tiles.Axes.(tileID),t_band,PSD_bands(chanSel,:,bCounter))
            bCounter = bCounter+1;
        end
        colorAx_green(signalTc.tiles.Axes.(tileID));        
    end
end