function [conn_index, file_index, fld_DS] = MLIO_buildDSDirectory(path_DS, DSCfg)
    % Check if exists
    %% DS DIRECTORY
    buildPath(path_DS);
    fld_DS = fullfile(path_DS,"DS");
    mkdir(fld_DS);
    % % index -- deprecated
    % file_index = fullfile(path_DS,"index.csv");
    % fid_index = fopen(file_index,"a");        
    % % fid_index_r = fopen(file_index,"r");
    %% DATABASE
    % Database setup (creates file if not already there)
    file_index = fullfile(path_DS,"index_ds.db");
    % addressFields =convertCharsToStrings(fieldnames(sampleAddress));% store for assertion of unique samples in database
    conn_index = MLIO_openDataBase(file_index);    
    %% CFG SAVE
    
    save(fullfile(path_DS,"DSCfg.mat"),"DSCfg");
end