function nexAccumulate_std(df_acc, df, n)
    % Welford's method of computing standard deviation by accumulation
    df_acc(~isnan(df)) = df_acc + (df-df_acc) * (df-)
end