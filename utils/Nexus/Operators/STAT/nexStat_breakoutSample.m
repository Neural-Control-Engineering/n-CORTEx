function sampleSet = nexStat_breakoutSample(DF, Y, SS_ax)
    % Y: a list of sample labels
    % DF: a dataframe struct to be parsed into sample data by...
    % SS_ax: an axis-wise selection of dfs (sub dataframes) to be sliced and kept
    if ~isempty(DF.df)
        dfSet = nexStat_breakoutDF(DF, SS_ax);
        ySet = repmat(Y, height(dfSet),1);
        sampleSet = [dfSet, ySet];
    else
        sampleSet = [];
    end
end