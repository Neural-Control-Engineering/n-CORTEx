function [pathsOut] = setPaths(paths, source)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% If code is being run from a mac
if ismac
    [~,user] = system('id -F');

    % Cody's macbook
    if strcmp(convertCharsToStrings(user(1:end-1)),'Cody Slater') % Right now this is a little strange need to account for a newline at end of mac username
        % Path for analysis code repo
        paths.repo_path = '/Users/codyslater/Documents/GitHub/Neuromodulation_for_Pain_Analysis';

        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('/Users/codyslater/Library/CloudStorage/GoogleDrive-cs3791@columbia.edu/My Drive/#Projects/',source);

        % ADD additional mac users here
    end

    % If code is being run from a pc
elseif ispc

    % Cody's primary PC
    if strcmp(getenv("COMPUTERNAME"),'BETADROID')
        % Path for analysis code repo
        paths.repo_path = 'B:\GitHub\Neuromodulation_for_Pain_Analysis';

        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'B:\GitHub\Neuropixel_Analysis_Scripts';
        paths.neuropixel.workingdir = 'A:\';

        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\My Drive\#Projects\',source);
    
    % Primus
    elseif strcmp(getenv("COMPUTERNAME"),'DESKTOP-MRI7THQ')
        % Path for analysis code repo
        % paths.repo_path = 'C:\Neuromodulation_for_Pain_Analysis';
        paths.repo_path = 'C:\STATIC';

        % Kilosort repository
        % paths.neuropixel.kilosort_repo = 'C:\Neuropixel_Analysis_Scripts\Kilosort';
        paths.neuropixel.kilosort_repo = 'C:\STATIC\Extraction\Modalities\Neuropixels\Utils\Kilosort';
        paths.neuropixel.workingdir = 'C:\';

        % Drive letter for analyzed data in customary file structure        
        paths.all_data_path = strcat('G:\My Drive\#Projects\',source);
        paths.projDir_cloud = strcat('G:\My Drive\#Projects\',source);
        paths.projDir_local = fullfile('C:','SGL_Data',source);

        % Path for raw npxls data
        paths.rawNpxlsPath = strcat('C:\SGL_Data\', source);
        paths.raw_neuropixel_data = fullfile('C:','SGL_Data',source,'Raw_Neuropixel_Data');
        % Local path for kilosorted data
        paths.ksortNpxlsPath = strcat('C:\SGL_Data\',source,'\Extracted_Neuropixel_Data');
        % path for realtime behavior data
        paths.rawBehaviorPath = fullfile('G:\My Drive\#Projects\',source);
        % raw data paths
        % paths.rawData = struct;
        % paths.rawData.LFP = struct;
        % paths.rawData.LFP.local = fullfile(paths.rawNpxlsPath,"Raw_Neuropixel_Data");
        % paths.rawData.LFP.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Neuropixels');
        % paths.rawData.AP = struct;
        % paths.rawData.AP.local = fullfile(paths.rawNpxlsPath,"Raw_Neuropixel_Data");
        % paths.rawData.AP.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Neuropixels');
        % paths.rawData.SLRT = struct;
        % paths.rawData.SLRT.local = [];
        % paths.rawData.SLRT.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Behavior','SLRT');
        % paths.rawData.Pupil = struct;
        % paths.rawData.Pupil.local = [];
        % paths.rawData.Pupil.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Pupil');
        % paths.rawData.Whisker = struct;
        % paths.rawData.Whisker.local = [];
        % paths.rawData.Whisker.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Whisker');
    
    % Qi's PC    
    elseif strcmp(getenv("COMPUTERNAME"),'DESKTOP-8JHPI5Q')
        % Path for analysis code repo
        paths.repo_path = 'C:\GitHub\Neuromodulation_for_Pain_Analysis';
        
        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'C:\GitHub\Neuropixel_Analysis_Scripts\Kilosort';
        paths.neuropixel.workingdir = 'C:\GitHub\Neuropixel_Analysis_Scripts';

        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\.shortcut-targets-by-id\1TXjzfxqMX-XrHs0K8dmSsXDsY65lVN57\',source);
        % Add additional PCs here:

    % Chancelor PC
    elseif strcmp(getenv("COMPUTERNAME"), 'DESKTOP-PSTAOLM')
        % Path for analysis code repo
        paths.repo_path = 'C:\Users\Chancelor\Documents\GitHub\Neuromodulation_for_Pain_Analysis';
        
        % Kilosort repository
        paths.neuropixel.kilosort_repo = 'C:\Users\Chancelor\Documents\GitHub\Neuropixel_Analysis_Scripts\Kilosort';
        paths.neuropixel.workingdir = 'C:\Users\Chancelor\Documents\GitHub\Neuropixel_Analysis_Scripts';

        % Drive letter for raw and analyzed data in customary file structure
        paths.all_data_path = strcat('G:\.shortcut-targets-by-id\1TXjzfxqMX-XrHs0K8dmSsXDsY65lVN57\',source);
        % Add additional PCs here:
    end
elseif isunix
    hostname = getenv("USER");    
    % paths.repo_path = 'C:\STATIC';

    % Kilosort repository
    % paths.neuropixel.kilosort_repo = 'C:\Neuropixel_Analysis_Scripts\Kilosort';
    % paths.neuropixel.kilosort_repo = 'C:\STATIC\Extraction\Modalities\Neuropixels\Utils\Kilosort';
    % paths.neuropixel.workingdir = 'C:\';

    % Drive letter for analyzed data in customary file structure        
    % paths.all_data_path = strcat('G:\My Drive\#Projects\',source);
    % paths.projDir_cloud = strcat('G:\My Drive\#Projects\',source);
    paths.projDir_cloud = fullfile("/home",hostname,"NEC_Drive",source);
    paths.projDir_local = fullfile("/home",hostname,"NEC_Drive_local", source);

    % Path for raw npxls data    
    paths.rawNpxls_local = fullfile('C:','SGL_Data',source,'Raw_Neuropixel_Data');
    paths.rawNpxls_cloud = [];
    paths.raw_neuropixel_data = fullfile('C:','SGL_Data',source,'Raw_Neuropixel_Data');
    paths.neuropixel.kilosort_repo = 'C:\STATIC\Extraction\Modalities\Neuropixels\Utils\Kilosort';
    paths.neuropixel.workingdir = 'C:\';
    % paths.rawNpxlsPath = strcat('C:\SGL_Data\', source);
    % Local path for kilosorted data
    % paths.ksortNpxlsPath = strcat('C:\SGL_Data\',source,'\Extracted_Neuropixel_Data');
    % path for realtime behavior data
    % paths.rawBehaviorPath = fullfile('G:\My Drive\#Projects\',source);
    % raw data paths
    % paths.rawData = struct;
    % paths.rawData.LFP = struct;
    % paths.rawData.LFP.local = [];
    % paths.rawData.LFP.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Neuropixels');
    % paths.rawData.AP = struct;
    % paths.rawData.AP.local = [];
    % paths.rawData.AP.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Neuropixels');
    % paths.rawData.SLRT = struct;
    % paths.rawData.SLRT.local = [];
    % paths.rawData.SLRT.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Behavior','SLRT');
    % paths.rawData.Pupil = struct;
    % paths.rawData.Pupil.local = [];
    % paths.rawData.Pupil.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Pupil');
    % paths.rawData.Whisker = struct;
    % paths.rawData.Whisker.local = [];
    % paths.rawData.Whisker.cloud = fullfile(paths.projDir_cloud,'Data','Raw-Data','Whisker');
end

% Paths for raw data
% paths.raw_neuropixel_data = fullfile(paths.rawNpxlsPath,'Raw_Neuropixel_Data');
% paths.raw_behavior_data = fullfile(paths.all_data_path,'Data','Raw-Data','Behavior'); % NI files are in same folder as neuropixels
% paths.experiment_details = fullfile(paths.rawNpxlsPath,'Experiment-Details');

% Paths for analyzed data
% paths.processed_neuropixel_data = fullfile(paths.all_data_path,'Processed-Neuropixel-Data');
% paths.processed_behavior_data = fullfile(paths.all_data_path,'Processed-Behavior-Data');
% paths.datastores = fullfile(paths.all_data_path,'Datastores');

% Store which project data is actively being used
% paths.data_source = source;

% Store neuropixel related paths
paths.neuropixel.kilosort_params = fullfile(paths.raw_neuropixel_data,"Kilosort_params");
paths.neuropixel.npy = fullfile(paths.neuropixel.kilosort_repo,'npy-matlab-master','npy-matlab');
paths.neuropixel.config = convertStringsToChars(fullfile(paths.raw_neuropixel_data,'Kilosort_params'));

setenv("NEUROPIXEL_MAP_FILE",fullfile(paths.neuropixel.config,"neuropixPhase3A_kilosortChanMap.mat"))
setenv("KILOSORT_CONFIG_FILE",fullfile(paths.neuropixel.config,"StandardConfig.m"))
pathsOut = paths;
end