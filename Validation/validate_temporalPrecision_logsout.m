function validate_temporalPrecision_logsout(logsout, Fs) 
    
    % NOTE: logsout assumes external is the longest wavelength

    Fs1 = Fs;
    Fs2 = Fs;
    % expecting a single external sync pulser
    % expecting multiple internl sync pulsers? (some faster or slower)
    signalNames = logsout.getElementNames;
    syncSignals = cellfun(@(x) contains(x,"sync"), signalNames, "UniformOutput",true);
    syncSignals = convertCharsToStrings(signalNames(syncSignals==1));
    externalsync = syncSignals(contains(syncSignals,"ext"));
    internalsync = syncSignals(contains(syncSignals,"int"));
    % evaluate
    sync1 = logsout.get(externalsync).Values;
    F_sync1 = extractSyncFrequency(externalsync);
    args.groupSize = 10;
    % validation Figure
    validationFigure.fh = uifigure("Position",[50,50,705,300],"Color",[0,0,0]);
    validationFigure.panel1.ph = uipanel(validationFigure.fh,"Position",[5,5,345,290],"BackgroundColor",[0,0,0]);
    validationFigure.panel2.ph = uipanel(validationFigure.fh,"Position",[355,5,345,290],"BackgroundColor",[0,0,0]);
    numTiles_IPD = size(externalsync,1) + size(internalsync,1);
    numTiles_PC = size(internalsync,1);
    validationFigure.panel1.tiles.t = tiledlayout(validationFigure.panel1.ph,numTiles_IPD,1);    
    validationFigure.panel2.tiles.t = tiledlayout(validationFigure.panel2.ph,numTiles_PC,1);        
    % plot longest wavelength pulse IPD and PC (trivial)
    for i = 1:length(internalsync)
        internalsync_i = internalsync(i);
        F_sync2 = extractSyncFrequency(internalsync_i);
        sync2 = logsout.get(internalsync_i).Values;
        [IPD_A, IPD_B, PC_B] = validate_temporalPrecision(sync1.Data', sync2.Data', Fs1, Fs2, F_sync1, F_sync2, args);
        % visualize results
        tileTag = sprintf("t%d",i);
        if i == 1
            validationFigure.panel1.tiles.Axes.IPD.(tileTag) = nexttile(validationFigure.panel1.tiles.t);            
            plot(validationFigure.panel1.tiles.Axes.IPD.(tileTag), IPD_A.mean_tc);
            colorAx_green(validationFigure.panel1.tiles.Axes.IPD.(tileTag));        

            validationFigure.panel1.tiles.Axes.IPD.(tileTag) = nexttile(validationFigure.panel1.tiles.t);            
            plot(validationFigure.panel1.tiles.Axes.IPD.(tileTag), IPD_B.mean_tc);
            colorAx_green(validationFigure.panel1.tiles.Axes.IPD.(tileTag));        

            validationFigure.panel2.tiles.Axes.PC.(tileTag) = nexttile(validationFigure.panel2.tiles.t);
            plot(validationFigure.panel2.tiles.Axes.PC.(tileTag),PC_B.mean_tc);
            colorAx_green(validationFigure.panel2.tiles.Axes.PC.(tileTag));        
        else          
           validationFigure.panel1.tiles.Axes.IPD.(tileTag) = nexttile(validationFigure.panel1.tiles.t);            
            plot(validationFigure.panel1.tiles.Axes.IPD.(tileTag), IPD_B.mean_tc);
            colorAx_green(validationFigure.panel1.tiles.Axes.IPD.(tileTag));        

            validationFigure.panel2.tiles.Axes.PC.(tileTag) = nexttile(validationFigure.panel2.tiles.t);
            plot(validationFigure.panel2.tiles.Axes.PC.(tileTag),PC_B.mean_tc);
            colorAx_green(validationFigure.panel2.tiles.Axes.PC.(tileTag));        
        end        
    end   
    
    
    

end