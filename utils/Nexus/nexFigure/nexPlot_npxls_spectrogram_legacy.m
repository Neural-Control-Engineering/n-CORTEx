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
    % spgFigure.Ax.CLim=[-11.2,-8.5];

    % chanSel = 1;
    % signalSpG.fh = uifigure("Position",[100,1260,500,500],"Color",[0,0,0]);   
    % signalSpG.ph = uipanel(signalSpG.fh,"Position",[5,5,490,490],"BackgroundColor",[0,0,0]);
    % PSD = timeCourse.UserData.PSD;
    % f_psd = timeCourse.UserData.f_psd;    
    % SpG = PSD(chanSel,:,:);
    % t_psd = [1:size(SpG,3)]./500 - 3.5;
    % signalSpG.Ax = axes(signalSpG.ph);
    % imagesc(signalSpG.Ax,"YData",f_psd,"XData",t_psd,"CData",log10(squeeze(SpG)));
    % colorAx_green(signalSpG.Ax);
    % signalSpG.Ax.CLim=[-11.2,-8.5];
    % S2
    % signalSpG.fh2 = uifigure("Position",[100,1260,500,500],"Color",[0,0,0]);   
    % signalSpG.ph2 = uipanel(signalSpG.fh2,"Position",[5,5,490,490],"BackgroundColor",[0,0,0]);
    % signalSpG.Ax2 = axes(signalSpG.ph2);
    % [PSD_fullWindow, f_psdFull] = pmtm(lfp(:,1750:3750)', 10, 2048, 500 ,'Tapers','sine');     
    % fCond = (f_psdFull <= 50);
    % imagesc(signalSpG.Ax2,"YData",[1:385],"XData",f_psdFull(fCond==1),"CData",log10(PSD_fullWindow(fCond==1,:)'));
    % signalSpG.Ax2.CLim=[-11.2,-8.5];
    % colorAx_green(signalSpG.Ax2);
end