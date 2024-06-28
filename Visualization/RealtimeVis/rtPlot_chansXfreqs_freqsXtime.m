function rtPlot_chansXfreqs_freqsXtime(Ax, streamCfg, SFT)
    
    Ax1 = Ax{1};
    Ax2 = Ax{2};
    % Ax.CData =[];
    f = SFT{1,2}{1};
    t = SFT{1,3}{1};
    S = SFT{1,1};
    sAvg = cellfun(@(x) mean(10*log10(abs(x)),2),S,"UniformOutput",false);
    sChans = [sAvg{:}]';
    Ax1.CData = gather(sChans);
    drawnow;
    Ax1.XData = gather(f);

    stftIdx = streamCfg.chanViewSel;
    Ax2.CData = gather(10*log10(abs(S{stftIdx})));    
    drawnow

end