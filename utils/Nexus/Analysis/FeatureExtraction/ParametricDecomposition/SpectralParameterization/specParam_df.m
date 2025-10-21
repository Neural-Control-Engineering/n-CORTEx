function [specs, scores] = specParam_df(f, df_in)
    args = extractMethodCfg('spectralParameterization');
    [specs, scores] = specParam(f', squeeze(df_in), args, 'specparam');    
end