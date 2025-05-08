function uiUpdateSpecs(dash)
    % remove fourth line (if exists)    
    plts = get(dash.panel1.pltAx,"Children");
    for i = 1:size(plts,1)        
        if size(plts,1) > 3
            delete(plts(1));            
        end
        plts = get(dash.panel1.pltAx,"Children");
    end          
    sig = composeSpecs(dash.fh.UserData.specs.freq,dash.fh.UserData.specs);    
    % add sig to plot
    sigLine = line(dash.fh.UserData.specs.freq,sig,"Parent",dash.panel1.pltAx,"Color",[0.0588    1.0000    1.0000]);       
    drawnow;
end