function panelOut = df2Fig_trace(panel,data, dataFrame, label)
    % fh = figure('visible','off');
    subplot(1,1,1,'Parent',panel);
    traceAx = data.axs.(data.axs.traceAx);
    plot(dataFrame);    
    xlim([1,length(traceAx)]);
    ylim([-1,3]);
    panelOut = panel;
    % xlabel("channels");
    % ylabel("LFP");         
end