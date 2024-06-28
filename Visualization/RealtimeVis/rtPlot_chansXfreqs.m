function rtPlot_chansXfreqs(Ax, SFT)
    
    Ax.CData =[];
    f = SFT{1,2}{1};
    t = SFT{1,3}{1};
    S = SFT{1,1};
    sAvg = cellfun(@(x) mean(10*log10(abs(x)),2),S,"UniformOutput",false);
    sChans = [sAvg{:}]';
    Ax.CData = gather(sChans);
    Ax.XData = gather(f);
    drawnow
    
end