function fh = df2Gif_NT(data, dataFrame, label)
    fh = figure;        
    % imagesc
    % t = data.axs.t;
    % f = data.axs.f;
    chan = data.axs.chan;
    imagesc(dataFrame);    
    title(label);    
    % xlabel("freq (Hz)");
    % ylabel("channel");    
    daspect([18,14,1]);
    % zlabel("power (10*log10(|z|)")
    colorbar
    caxis(data.caxis);
end