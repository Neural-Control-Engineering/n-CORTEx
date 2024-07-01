function rtPlot_chansXfreqs_freqsXtime_surf2(rtDash, streamCfg, SFT)
    
    % Ax1 = Ax{1};
    % Ax2 = Ax{2};
    % Ax1 = rtDash.panel1.imgAx;
    % Ax2 = rtDash.panel2.surfAx;
    Ax1 = rtDash.panel1.surfAx;
    Ax2 = rtDash.panel2.imgAx;
    % Ax.CData =[];
    f = SFT{1,2}{1};
    t = SFT{1,3}{1};
    S = SFT{1,1};
    sAvg = cellfun(@(x) mean(10*log10(abs(x)),2),S,"UniformOutput",false);
    sChans = [sAvg{:}]';
    stftIdx = streamCfg.chanViewSel;   
    
    Ax1.YData = gather([1:size(sChans,1)]);
    Ax1.XData = gather(f);
    Ax1.ZData = gather(sChans);    
    Ax1.CData = gather(sChans);    

    Ax2.CData = gather(10*log10(abs(S{stftIdx})));    
    Ax2.XData = gather(f);

    drawnow

end