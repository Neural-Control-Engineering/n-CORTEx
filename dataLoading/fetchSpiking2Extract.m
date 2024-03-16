function [neuropixel_to_process] = fetchSpiking2Extract(animal_id,session_names,paths,reset_neuropixel_processing)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if reset_neuropixel_processing==true
    % Reset the analysis log
    load(fullfile(paths.raw_neuropixel_data,"neuropixel_extraction_log.mat"));
    neuropixel_extraction_log(contains(neuropixel_extraction_log.Name, animal_id),:) = [];
    
    save(fullfile(paths.raw_neuropixel_data,'neuropixel_extraction_log.mat'),'neuropixel_extraction_log');
end

% List all neuropixel files in folder
neuropixel_list = session_names(:,1);
neuropixel_list = neuropixel_list(contains(neuropixel_list,animal_id));
filenames = neuropixel_list;

%
load(fullfile(paths.raw_neuropixel_data,"neuropixel_extraction_log.mat"));

if ~isempty(neuropixel_extraction_log)
    idx_neuropixel_to_add =  ~ismember(filenames,neuropixel_extraction_log.Name);
else
    idx_neuropixel_to_add = true(1, length(filenames));
end

files_to_add = filenames(idx_neuropixel_to_add);

if ~isempty(files_to_add)
    for i = 1:length(files_to_add)
        % Add new data files to analysis list and set processed to false
        neuropixel_extraction_log = [neuropixel_extraction_log; {files_to_add(i), false}];
        display(strcat("Added:  ",files_to_add(i),' to the neuropixel extraction log.'));
    end
end

% Return videos that need to be extracted
neuropixel_to_process = neuropixel_extraction_log(neuropixel_extraction_log.Processed == false & contains(neuropixel_extraction_log.Name,animal_id),:).Name;

if ~isempty(neuropixel_to_process)
    save(fullfile(paths.raw_neuropixel_data,'neuropixel_extraction_log.mat'),'neuropixel_extraction_log');
else
    display(strcat("There are currently no neuropixel files for ",animal_id, ' that need to be processed.'));
end
end