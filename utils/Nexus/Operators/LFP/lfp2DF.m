function DF = lfp2DF(lfp, t)
    % convert lfp into DF with defined axes
    DF.df = lfp;
    DF.ax.t = t;
    DF.ax.chans = [1:size(lfp,1)];
end