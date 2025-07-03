function [df_avg_out, df_std_out] = nexStat_welfordsAverage(df, df_avg, df_std, n_avg)
    df_avg_out = df_avg;
    df_std_out = df_std;
    idx_acc = ~isnan(df);
    % accumulate mean and std
    df_avg_out(idx_acc) = df_avg(idx_acc) + (df(idx_acc) - df_avg(idx_acc)) ./ n_avg;
    df_std_out(idx_acc) = df_std(idx_acc) + (df(idx_acc)-df_avg(idx_acc)).*(df(idx_acc)-df_avg_out(idx_acc));

end