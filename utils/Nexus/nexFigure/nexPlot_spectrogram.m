function  nexPlot_spectroGram(nexon, spectroGram)
   
    % DRAW CFG PANELS AND FIGURES
    spectroGram.spgFigure.fh = uifigure("Position",[100,1260,1000,550],"Color",[0,0,0]);   
    spectroGram.spgFigure.panel1.ph = uipanel(spectroGram.spgFigure.fh,"Position",[5,10,800,495],"BackgroundColor",[0,0,0]);           
    % visCfg panel
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    visArgs = spectroGram.visCfg.entryParams;
    panel2.ph = uipanel(spectroGram.spgFigure.fh,"Position",[805,10,90,495],"BackgroundColor",[0,0,0]);
    visCfgEntryArgs.yStepScaler = 35;
    visCfgEntryArgs.entryHeightScaler = 20;
    spectroGram.spgFigure.panel2 = nexObj_cfgPanel(nexon, spectroGram, panel2, visArgs, visCfgEntryChangedFcn, visCfgEntryArgs); % convert base panel to nexPanel (handle class)
    % opCfg panel    
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    opArgs = spectroGram.opCfg.entryParams;
    panel3.ph = uipanel(spectroGram.spgFigure.fh,"Position",[900,10,90,495],"BackgroundColor",[0,0,0]);
    spectroGram.spgFigure.panel3 = nexObj_cfgPanel(nexon, spectroGram, panel3, opArgs, opCfgEntryChangedFcn, []); % convert base panel to nexPanel (handle class)
    % plot axes
    spectroGram.spgFigure.panel1.tiles.t=tiledlayout(spectroGram.spgFigure.panel1.ph,1,1);
    spectroGram.spgFigure.panel1.tiles.Axes.spectroGram = nexttile(spectroGram.spgFigure.panel1.tiles.t);
    spectroGram.spgFigure.panel1.tiles.Axes.spectroGram = imagesc(spectroGram.spgFigure.panel1.tiles.Axes.spectroGram);
    % figure color mapping            
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(spectroGram.spgFigure.fh,CT);
    colorAx_green(spectroGram.spgFigure.panel1.tiles.Axes.spectroGram.Parent);
    % visualize
    spectroGram.visCfg.visFcn(nexon, spectroGram, visArgs);  

end