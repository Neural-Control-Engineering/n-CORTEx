function panelOut = df2Fig_channelgram(panel,data, dataFrame, label)
    % fh = figure('visible','off');    
    % t=tiledlayout(1,2);   
    subplot(1,2,1,'Parent',panel);
    % title(t, label);
    % nexttile(t);    
    % subplot(1,2,1);
    f = data.axs.f;
    chan = data.axs.chan;
    imagesc(f(f<50), chan, dataFrame(:,f<50));    
    xlabel("freq (Hz)");
    ylabel("channel");    
    % zlabel("power (10*log10(|z|)")
    colorbar
    colormap cool
    caxis([-40,-30]); % SINGLE
    % caxis([-5,15]); % DIFF
    % nexttile(t);
    subplot(1,2,2,'Parent',panel);
    % iso
    % surf(flip(f(f<50),2), flip(chan,2), flip(dataFrame(:,f<50),2));
    surf((f(f<50)), (chan), (dataFrame(:,f<50)),'EdgeColor','none');
    set(gca,'Xdir','reverse');
    view(160,50);
    xlabel("freq (Hz)");
    ylabel("channel");
    zlabel("power (10*log10(|z|)");    
    zlim([-80, -20]) % SINGLE
    % zlim([-40,40]) % DIFF
    % fh.WindowState = 'maximized';
    % set(gcf, 'Position', [100, 100, 1200, 600]);  
    colormap cool
    caxis([-40,-30]); % SINGLE
    % caxis([-5,15]);
    panelOut = panel;
end
