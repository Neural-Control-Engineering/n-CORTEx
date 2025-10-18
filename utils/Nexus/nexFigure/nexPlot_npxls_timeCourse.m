function timeCourse =  nexPlot_npxls_timeCourse(nexon, shank, timeCourse)
    router = nexon.console.BASE.router;
    params = nexon.console.BASE.params;
    df = timeCourse.dataFrame;
    dfID = timeCourse.dfID;
    timeCourse.tcFigure.fh =uifigure("Position",[25,560,1000, 1300],"Color",[0,0,0]);
    load(fullfile(params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    timeCourse.tcFigure.panel1.ph1 = uipanel(timeCourse.tcFigure.fh,"Position",[5,5,990,1260],"BackgroundColor",[0,0,0]);  
    % draw buttons
    timeCourse.tcFigure.nextButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon, shank,  timeCourse, 1),"Position",[965,1270,25,15]); % next
    timeCourse.tcFigure.prevButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)tileShift(nexon, shank, timeCourse, 0),"Position",[935,1270,25,15]); % prev
    timeCourse.tcFigure.PSDButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)loadPSDTimeCourse(nexon, shank, timeCourse),"Position",[5,1270,25,25]);
    timeCourse.tcFigure.LFPButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)loadLFPTimeCourse(nexon, shank, timeCourse),"Position",[35,1270,25,25]);
    timeCourse.tcFigure.RegionCompressButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)npxlsRegionPool(nexon, shank, timeCourse, "average"),"Position",[65, 1270, 25, 25]);
    timeCourse.tcFigure.saveFigButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)exportNpxlsTimeCourse(nexon,shank,timeCourse),"Position",[905,1270,25,25]);
    timeCourse.tcFigure.methodApplyButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)applyMethod(nexon, shank, timeCourse), "Position",[95,1270,25,25]);
    timeCourse.tcFigure.methodSelectButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)selectMethod(nexon, shank, timeCourse),"Position",[125,1270,25,25]);
    % timeCourse.tcFigure.methodOutputSaveButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)saveMethodOutput(nexon,shank,timeCourse,"Position",[155,1270,25,25]));
    timeCourse.tcFigure.reportAverageButton = uibutton(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"ButtonPushedFcn",@(~,~)timeCourse.reportAverage([]),"Tooltip","reportAverage","Position",[185,1270,25,25]);
    updateDfIDFcn = str2func("nexUpdate_dfID");
    timeCourse.tcFigure.dfIDEditField = uieditfield(timeCourse.tcFigure.fh,"BackgroundColor",[0,0,0],"FontColor",nexon.settings.Colors.cyberGreen,"Position",[755, 1270, 145, 25], "Value",timeCourse.dfID,"ValueChangedFcn",@(src,event)updateDfIDFcn(src,event,nexon,timeCourse));
    % timeCourse.tcFigure.APButton
    % idxCond = contains(nexon.console.BASE.UserData.DTS.sessionLabel,router.subject) & contains(nexon.console.base.UserData.DTS.sessionLabel,router.date) & contains(nexon.console.base.UserData.DTS.sessionLabel,router.phase) & ((router.trial)==nexon.console.base.UserData.DTS.trialNumber);
    % dtsIdx = find(idxCond);
    % % draw router UI
    % drawNpxlsRouter(nexon);
    % % Plot initial traces
    % lfpRow = nexon.console.base.UserData.DTS(dtsIdx,:);
    % lfp = lfpRow.lfp{1};    
    numChans = size(df,1);
    numTiles = 20;
    % numPans = ceil(numChans / numTiles);    
    timeCourse.tcFigure.panel1.tiles.t = tiledlayout(timeCourse.tcFigure.panel1.ph1,numTiles,1,"TileSpacing","tight");    
    % nexon.console.npxlsLFP.UserData.lfp = df;    
    regMap = shank.regMap;
    regMap.channel=arrayfun(@(x) x{1}, regMap.channel, "UniformOutput",true);
    for i = 1:numTiles        
        tileID = sprintf("tile%d",i);
        timeCourse.tcFigure.panel1.tiles.Axes.(tileID) = nexttile(timeCourse.tcFigure.panel1.tiles.t);        
        traceColor = sprintf("#%s",regMap(regMap.channel==i,:).color{1});
        regName = regMap(regMap.channel==i,:).region{1};
        plot(timeCourse.tcFigure.panel1.tiles.Axes.(tileID),df(i,:),"Color",traceColor);
        timeCourse.tcFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);                       
        colorAx_green(timeCourse.tcFigure.panel1.tiles.Axes.(tileID));        
    end    
    timeCourse.UserData.tilePtr=1;
end