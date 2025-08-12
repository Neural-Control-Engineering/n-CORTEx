function [DF_avg_out, DF_std_out] = nexAccumulate_average(DF_avg, DF_std, DF, n_avg)
    % new mean = old_mean + (new_val-old_mean)/n
    % PLUS: Welford's method of computing standard deviation by accumulation
    % inputs and outpus
    % df_acc_avg_out=df_acc_avg_in;
    % df_acc_std_out=df_acc_std_in;
    % % accumulate mean and std (welford's)
    % df_acc_avg_out(~isnan(df)) = df_acc_avg_in + (df-df_acc_avg_in)./n;
    % df_acc_std_out(~isnan(df)) = df_acc_std_out + (df-df_acc_avg_in)*(df-df_acc_avg_out);

    % inputs/outputs:
    % DF
    % n_avg
    % DF_acc _avg (out/in)
    % DF_acc_std (out/in)
    DF_avg_out = DF_avg;
    DF_std_out = DF_std;
    
    if isstruct(DF.df)
        df_cell = struct2cell(DF.df);
        df_avg_cell = struct2cell(DF_avg.df);
        df_std_cell = struct2cell(DF_std.df);
        [df_avg_out, df_std_out] = cellfun(@(df, df_avg, df_std) nexStat_welfordsAverage(df, df_avg, df_std, n_avg), df_cell, df_avg_cell, df_std_cell, "UniformOutput", false);
        % recompose
        DF_avg_out.df = cell2struct(df_avg_out, fieldnames(DF_avg.df),1);
        DF_std_out.df = cell2struct(df_std_out, fieldnames(DF_std.df),1);
        % check
        % all(DF_avg_out.df.PW==DF_avg.df.PW==1);
    else
        [df_avg_out, df_std_out] = nexStat_welfordsAverage(DF.df, DF_avg.df, DF_std/df, n_avg);
        DF_avg_out.df=df_avg_out;
        DF_std_out.df=df_std_out;
    end
end