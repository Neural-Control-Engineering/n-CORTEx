function panelOut = df2Gif_NT(panel, data, dataFrame, label)
    % fh = figure;    
    subplot(1,1,1,'Parent',panel);
    % imagesc
    % t = data.axs.t;
    % f = data.axs.f;
    chan = data.axs.chan;
    ih = imagesc(dataFrame);    
    % hh = heatmap(dataFrame);
    colormap(data.colorMap)
    title(label);    
    % xlabel("freq (Hz)");
    % ylabel("channel");    
    daspect([18,14,1]);
    % daspect([30,26,1]);
    % zlabel("power (10*log10(|z|)")
    colorbar
    % caxis(data.caxis);
    panelOut= panel;
end