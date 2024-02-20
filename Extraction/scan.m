function [cfg, data] = scan(params, data_ft)
    % browse datastream, scanning for artifacts / features
    cfg = params.ftCfg_databrws;
    ft_databrowser(cfg, data_ft);

    % apply segmentation (if specified)
    % ft_preprocessing(cfg, data);

    % save changes for next extraction
end