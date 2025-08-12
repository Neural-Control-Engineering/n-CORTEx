function nexPlot_npxls_LFP(nexon)
    router = nexon.console.base.UserData.params.router;
    params = nexon.console.base.UserData.params;
    nexon.console.npxlsLFP=uifigure("Position",[25,1260,1000, 1300],"Color",[0,0,0]);
    load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    nexon.console.npxlsLFP.UserData.panel1.ph1 = uipanel(nexon.console.npxlsLFP,"Position",[5,5,990,1260],"BackgroundColor",[0,0,0]);  
    % draw buttons
    nexon.console.npxlsLFP.UserData.nextButton = uibutton(nexon.console.npxlsLFP,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon,1),"Position",[965,1270,25,15]); % next
    nexon.UserData.console.npxlsLFP.UserData.nextButton = uibutton(nexon.console.npxlsLFP,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon,0),"Position",[935,1270,25,15]); % prev
    idxCond = contains(nexon.console.base.UserData.DTS.sessionLabel,router.subject) & contains(nexon.console.base.UserData.DTS.sessionLabel,router.date) & contains(nexon.console.base.UserData.DTS.sessionLabel,router.phase) & ((router.trial)==nexon.console.base.UserData.DTS.trialNumber);
    dtsIdx = find(idxCond);
    % draw router UI
    drawNpxlsRouter(nexon);
    % Plot initial traces
    lfpRow = nexon.console.base.UserData.DTS(dtsIdx,:);
    lfp = lfpRow.lfp{1};
    numChans = size(lfp,1);
    numTiles = 20;
    % numPans = ceil(numChans / numTiles);    
    nexon.console.npxlsLFP.UserData.panel1.tiles.t = tiledlayout(nexon.console.npxlsLFP.UserData.panel1.ph1,numTiles,1,"TileSpacing","tight");    
    nexon.console.npxlsLFP.UserData.lfp = lfp;    
    regMap = nexon.UserData.npxls.shanks.shank1.regMap;
    regMap.channel=arrayfun(@(x) x{1}, regMap.channel, "UniformOutput",true);
    for i = 1:numTiles        
        tileID = sprintf("tile%d",i);
        nexon.console.npxlsLFP.UserData.panel1.tiles.Axes.(tileID) = nexttile(nexon.console.npxlsLFP.UserData.panel1.tiles.t);        
        traceColor = sprintf("#%s",regMap(regMap.channel==i,:).color{1});
        regName = regMap(regMap.channel==i,:).region{1};
        plot(nexon.console.npxlsLFP.UserData.panel1.tiles.Axes.(tileID),lfp(i,:),"Color",traceColor);
        nexon.console.npxlsLFP.UserData.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);                       
        colorAx_green(nexon.console.npxlsLFP.UserData.panel1.tiles.Axes.(tileID));        
    end    
    nexon.console.npxlsLFP.UserData.tilePtr=1;
end