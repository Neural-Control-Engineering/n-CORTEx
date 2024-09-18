function updateSpecsDash(dash, f, psd, fit)    
    plts = get(dash.panel1.pltAx,"Children");
    if isempty(plts)
        plot(dash.panel1.pltAx, f, fit,"Color",[1,0,0.5333])
        hold(dash.panel1.pltAx,"on");
        plot(dash.panel1.pltAx, f, psd,"Color",[0.24,0.94,0.46])
    else
        for i = 1:size(plts,1)
            delete(plts(1));
            plts = get(dash.panel1.pltAx,"Children");       
        end
        % add sig to plot
        line(f,fit,"Parent",dash.panel1.pltAx,"Color",[1,0,0.5333]);
        line(f,psd,"Parent",dash.panel1.pltAx,"Color",[0.24,0.94,0.46]);    
    end
    colorAx_green(dash.panel1.pltAx);
    drawnow
end