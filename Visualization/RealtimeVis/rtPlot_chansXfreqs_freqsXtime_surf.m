function rtPlot_chansXfreqs_freqsXtime_surf(rtDash, streamCfg, SFT)
    
    % Ax1 = Ax{1};
    % Ax2 = Ax{2};
    Ax1 = rtDash.panel1.imgAx;
    Ax2 = rtDash.panel2.surfAx;
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
    Ax2.YData = gather(f);
    Ax2.XData = gather(t);
    Ax2.ZData = gather(10*log10(abs(S{stftIdx})));    
    Ax2.CData = gather(10*log10(abs(S{stftIdx})));    
    drawnow

end