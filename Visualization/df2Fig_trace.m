function panelOut = df2Fig_trace(panel,data, dataFrame, label)
    % fh = figure('visible','off');
    subplot(1,1,1,'Parent',panel);
    traceAx = data.axs.(data.axs.traceAx);
    plot(dataFrame);    
    xlim([1,length(traceAx)]);
    % ylim([0.24,0.35]);
    ylim([6, 22]);
    panelOut = panel;
    % xlabel("channels");
    % ylabel("LFP");         
end