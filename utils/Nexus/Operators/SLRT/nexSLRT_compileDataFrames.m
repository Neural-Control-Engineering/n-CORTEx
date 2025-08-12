function DF = nexSLRT_compileDataFrames(nexon, IDs_signals, IDs_events)
    dataFrames = {};
    % first appearing event dfID is signal dfID
    idx_signalDFIDs = arrayfun(@(sigID) contains(IDs_events, sigID), IDs_signals, "UniformOutput", false);
    idx_signalDFIDs = cellfun(@(matchFlags) find(matchFlags), idx_signalDFIDs, "UniformOutput", false);
    idx_signalDFIDs = cellfun(@(matchIdxs) matchIdxs(1), idx_signalDFIDs, "UniformOutput", true);
    DFIDs_signals = IDs_events(idx_signalDFIDs);
    for i = 1:length(IDs_signals)
        % dfID_i = dfID(i);
        sigID = IDs_signals(i);
        dfID_i = DFIDs_signals(contains(DFIDs_signals,sigID));
        dfID_i = strrep(dfID_i,sigID, sprintf("aligned_%s",sigID));
        dfID_t_i = sprintf("%s_time",dfID_i);
        df = grabDataFrame(nexon, dfID_i,[]);
        t = grabDataFrame(nexon, dfID_t_i,[]);
        DF.df.(dfID_i) = df;
        DF.ax.t.(dfID_i) = t;
        % df = dtsIO_readDF(nexon, dfID_i,[]);
        % dataFrames = [dataFrames; df'];
    end
end