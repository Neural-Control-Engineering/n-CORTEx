function nexPlot_npxls_channelGram(nexon, shank, channelGram)
    signalSpG.fh2 = uifigure("Position",[100,1260,500,500],"Color",[0,0,0]);   
    signalSpG.ph2 = uipanel(signalSpG.fh2,"Position",[5,5,490,490],"BackgroundColor",[0,0,0]);
    signalSpG.Ax2 = axes(signalSpG.ph2);
    [PSD_fullWindow, f_psdFull] = pmtm(lfp(:,1750:3750)', 10, 2048, 500 ,'Tapers','sine');     
    fCond = (f_psdFull <= 50);
    imagesc(signalSpG.Ax2,"YData",[1:385],"XData",f_psdFull(fCond==1),"CData",log10(PSD_fullWindow(fCond==1,:)'));
    signalSpG.Ax2.CLim=[-11.2,-8.5];
    colorAx_green(signalSpG.Ax2);
end