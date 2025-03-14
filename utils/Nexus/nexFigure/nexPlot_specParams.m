function nexPlot_specParams(specs)
    timeCourse.spcsFigure.fh =uifigure("Position",[25,560,1000, 1300],"Color",[0,0,0]);
    timeCourse.spcsFigure.panel1.ph1 = uipanel(timeCourse.spcsFigure.fh,"Position",[5,5,990,1260],"BackgroundColor",[0,0,0]);  
    numTiles = 5;
    timeCourse.spcsFigure.panel1.tiles.t = tiledlayout(timeCourse.spcsFigure.panel1.ph1,numTiles,1,"TileSpacing","tight");    
    for i = 1:numTiles
        switch i
            case 1 % OFF
                signal = specs.aperiodic_params(:,1);
            case 2 % AP
                signal = specs.aperiodic_params(:,2);
            case 3 % CF
                signal = cellfun(@(x) returnBetaPeak(x,1), specs.periodic_params(:),"UniformOutput",true);                               
            case 4 % PW
                signal = cellfun(@(x) returnBetaPeak(x,2), specs.periodic_params(:));                
            case 5 % BW
                signal = cellfun(@(x) returnBetaPeak(x,3), specs.periodic_params(:));                
        end

        tileID = sprintf("tile%d",i);
        timeCourse.spcsFigure.panel1.tiles.Axes.(tileID) = nexttile(timeCourse.spcsFigure.panel1.tiles.t);        
        % traceColor = sprintf("#%s",regMap(regMap.channel==i,:).color{1});
        % regName = regMap(regMap.channel==i,:).region{1};
        plot(timeCourse.spcsFigure.panel1.tiles.Axes.(tileID),t,signal);
        % timeCourse.spcsFigure.panel1.tiles.Axes.(tileID).YLabel.String = sprintf("%s", regName);                       
        colorAx_green(timeCourse.spcsFigure.panel1.tiles.Axes.(tileID));        
           
    end       
end