function nexFigure_fitScope(nexObj)
    % use model function and model parameters
    nexObj.Figure.fh = uifigure("Position",[100,1260,650,250],"Color",[0,0,0]);   
    % plot panel
    nexObj.Figure.panel1.ph = uipanel(nexObj.Figure.fh,"Position",[5,5,500,240],"BackgroundColor",[0,0,0]);
    % cfg panel
    nexObj.Figure.panel2.ph = uipanel(nexObj.Figure.fh,"Position",[510,5,135,240],"BackgroundColor",[0,0,0],"Scrollable","on");
    visCfgEntryChangedFcn = str2func("visCfgEntryChanged");
    nexObj.Figure.panel2 = nexObj_cfgPanel_spinner(nexObj.nexon,nexObj,nexObj.Figure.panel2,nexObj.visCfg.entryParams,visCfgEntryChangedFcn,[]);
end