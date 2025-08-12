function spgFigure = nexPlot_npxls_spectrogram(nexon, shank, spectroGram)

    dataFrame = spectroGram.dataFrame;
    chanSel = spectroGram.UserData.chanSel;
    f_psd = spectroGram.f;
    t_psd = spectroGram.t;
    spgFigure.fh = uifigure("Position",[100,1260,500,500],"Color",[0,0,0]);   
    spgFigure.ph = uipanel(spgFigure.fh,"Position",[5,5,490,490],"BackgroundColor",[0,0,0]);
    SPG = dataFrame(chanSel,:,:);
    spgFigure.Ax = axes(spgFigure.ph);
    imagesc(spgFigure.Ax,"YData",f_psd,"XData",t_psd,"CData",10*log10((squeeze(abs(SPG)))));
    colorAx_green(spgFigure.Ax);

end