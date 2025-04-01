function spgFigure = nexPlot_spectroGram(nexon, spectroGram)
   
    % DRAW CFG PANELS AND FIGURES
    spgFigure.fh = uifigure("Position",[100,1260,650,500],"Color",[0,0,0]);   
    spgFigure.panel1.ph = uipanel(spgFigure.fh,"Position",[5,10,645,350],"BackgroundColor",[0,0,0]);           
    % visCfg panel
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    visArgs = spectroGram.visCfg.entryParams;
    spgFigure.panel2.ph = uipanel(spgFigure.fh,"Position",[5,365,215,135],"BackgroundColor",[0,0,0]);
    spgFigure.panel2 = nexObj_cfgPanel(nexon, spectroGram spgFigure.panel2, visArgs, visCfgEntryChangedFcn, []); % convert base panel to nexPanel (handle class)
    % opCfg panel    
    opCfgEntryChangedFcn = str2func("opCfgEntryChanged");
    opArgs = spectroGram.opCfg.entryParams;
    spgFigure.panel3.ph = uipanel(spgFigure.fh,"Position",[225,365,215,135],"BackgroundColor",[0,0,0]);
    spgFigure.panel3 = nexObj_cfgPanel(nexon, spgFigure.panel3, opArgs, opCfgEntryChangedFcn); % convert base panel to nexPanel (handle class)
    
    spectroGram.visCfg.visFcn(nexon, spectroGram, visArgs);
    % SPG = dataFrame(chanSel,:,:);
    % spgFigure.Ax = axes(spgFigure.panel1.ph);
    % imagesc(spgFigure.Ax,"YData",f_psd,"XData",t_psd,"CData",10*log10((squeeze(abs(SPG)))));
    % colorAx_green(spgFigure.Ax);

end