function df_format = nexFormat_channelGram(nexObj, args)
    % format dataframe for export/analysis

    % CFG HEADER
    formatStyle = args.formatMode;

    switch formatStyle
        case "stack"
            % stack channelgram dfs by time series, with chan and freq labels
            % generateTensor_channelGram(df_chg, leadingDim);
            [df_format, labels] = stackTensor(tensor, leadingDim);
        case "batch"
            % arrange channelgram df as tensor

    end

end