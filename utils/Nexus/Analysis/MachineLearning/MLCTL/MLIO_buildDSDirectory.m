function [fid_index, fld_DS] = MLIO_buildDSDirectory(path_DS, DSCfg)
    % Check if exists
    % make directory
    buildPath(path_DS);
    fld_DS = fullfile(path_DS,"DS");
    mkdir(fld_DS);
    % index 
    file_index = fullfile(path_DS,"index.csv");
    fid_index = fopen(file_index,"w");
    % save DSCfg
    save("DSCfg.mat","DSCfg");
end