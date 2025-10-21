function  nexPlot_spectroGram(nexon, nexObj)
   
    % DRAW CFG PANELS AND FIGURES
    nexObj.Figure.fh = uifigure("Position",[100,1260,1000,550],"Color",[0,0,0]);   
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,10,800,495],"BackgroundColor",[0,0,0]);           
    % visCfg panel
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    visArgs = nexObj.visCfg.entryParams;
    panel2.ph = uipanel(nexObj.Figure.fh,"Position",[805,10,90,495],"BackgroundColor",[0,0,0]);
    visCfgEntryArgs.yStepScaler = 35;
    visCfgEntryArgs.entryHeightScaler = 20;
    nexObj.Figure.panel2 = nexObj_cfgPanel(nexon, nexObj, panel2, visArgs, visCfgEntryChangedFcn, visCfgEntryArgs); % convert base panel to nexPanel (handle class)
    % opCfg panel    
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    opArgs = nexObj.opCfg.entryParams;
    panel3.ph = uipanel(nexObj.Figure.fh,"Position",[900,10,90,495],"BackgroundColor",[0,0,0]);
    nexObj.Figure.panel3 = nexObj_cfgPanel(nexon, nexObj, panel3, opArgs, opCfgEntryChangedFcn, []); % convert base panel to nexPanel (handle class)
    % plot axes
    nexObj.Figure.panel1.tiles.t=tiledlayout(nexObj.Figure.panel1.ph,1,1);
    nexObj.Figure.panel1.tiles.Axes.spectroGram = nexttile(nexObj.Figure.panel1.tiles.t);
    nexObj.Figure.panel1.tiles.Axes.spectroGram = imagesc(nexObj.Figure.panel1.tiles.Axes.spectroGram);
    % User Input Buttons/Fields
    nexObj.Figure.addChildButton = uibutton(nexObj.Figure.fh,"BackgroundColor",[0,0,0], "ButtonPushedFcn",@(~,~)nexObj.addChild(),"Position",[5,520,25,25]);
    % figure color mapping            
    load(fullfile(nexon.console.BASE.params.paths.repo_path,"Visualization/RealtimeVis/cmap-cyberGreen.mat"));
    colormap(nexObj.Figure.fh,CT);
    colorAx_green(nexObj.Figure.panel1.tiles.Axes.spectroGram.Parent);
    % visualize
    nexObj.visCfg.visFcn(nexObj, visArgs);  

end