function dash = flipMaskShow(dash, panelRef, step)
    dash.(panelRef).maskIdx = dash.(panelRef).mskNum.Value;
    dash.(panelRef).maskIdx = dash.(panelRef).maskIdx+step;
    try
        dash.(panelRef).imgAx4.CData = dash.(panelRef).mskData(:,:,:,dash.(panelRef).maskIdx);
    catch e
        disp(e);
    end
    dash.(panelRef).mskNum.Value=dash.(panelRef).maskIdx;
    % dash.Q.send(dash.maskIdx);
    % dash.tAx4.Color=[0,0,0]
end