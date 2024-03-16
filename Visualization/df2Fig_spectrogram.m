function fh = df2Fig_spectrogram(data, dataFrame, label)
    fh = figure;
    t = tiledlayout(1,2);
    title(t, label);
    nexttile
    % imagesc
    t = data.axs.t;
    f = data.axs.f;
    chan = data.axs.chan;
    imagesc(f(f<50), t, dataFrame(:,f<50));    
    imagesc(f(f<50),t,dataFrame((f<50),:))
    xlabel("freq (Hz)");
    ylabel("time (sec)");    
    % zlabel("power (10*log10(|z|)")
    colorbar
    % caxis(data.caxis);
    nexttile
    % iso
    % surf(flip(f(f<50),2), flip(chan,2), flip(dataFrame(:,f<50),2));    
    surf(t,f(f<50),dataFrame((f<50),:)) 
    set(gca,'Xdir','reverse');
    view(160,50);
    xlabel("freq (Hz)");
    ylabel("time (sec)");
    zlabel("power (10*log10(|z|)");    
    colorbar
    % caxis(data.caxis);
    fh.WindowState = 'maximized';
end