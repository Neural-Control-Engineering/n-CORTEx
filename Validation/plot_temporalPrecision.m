function plot_temporalPrecision(IPD_A, IPD_B, PC_B)

     % validation Figure
    validationFigure.fh = uifigure("Position",[50,50,705,300],"Color",[0,0,0]);
    validationFigure.panel1.ph = uipanel(validationFigure.fh,"Position",[5,5,345,290],"BackgroundColor",[0,0,0]);
    validationFigure.panel2.ph = uipanel(validationFigure.fh,"Position",[355,5,345,290],"BackgroundColor",[0,0,0]);
    % numTiles_IPD = size(externalSynch,1) + size(internalSynch,1);
    numTiles_IPD = 2;
    % numTiles_PC = size(internalSynch,1);
    numTiles_PC = 1;
    validationFigure.panel1.tiles.t = tiledlayout(validationFigure.panel1.ph,numTiles_IPD,1);    
    validationFigure.panel2.tiles.t = tiledlayout(validationFigure.panel2.ph,numTiles_PC,1);        

    tileTag = "t1";
    validationFigure.panel1.tiles.Axes.IPD.(tileTag) = nexttile(validationFigure.panel1.tiles.t);            
    plot(validationFigure.panel1.tiles.Axes.IPD.(tileTag), IPD_A.mean_tc);
    colorAx_green(validationFigure.panel1.tiles.Axes.IPD.(tileTag));        

    validationFigure.panel1.tiles.Axes.IPD.(tileTag) = nexttile(validationFigure.panel1.tiles.t);            
    plot(validationFigure.panel1.tiles.Axes.IPD.(tileTag), IPD_B.mean_tc);
    colorAx_green(validationFigure.panel1.tiles.Axes.IPD.(tileTag));        

    if ~isempty(PC_B)
        validationFigure.panel2.tiles.Axes.PC.(tileTag) = nexttile(validationFigure.panel2.tiles.t);
        plot(validationFigure.panel2.tiles.Axes.PC.(tileTag),PC_B.mean_tc);
        colorAx_green(validationFigure.panel2.tiles.Axes.PC.(tileTag));        
    end

end