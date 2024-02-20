function alignExtractionLog(params, modality, ftype)
    % given modality, find associated raw data paths and scan for existing
    % sessions to rebuild extraction log
    % subjectNames = readtable(fullfile(params.paths.projDir_cloud,"Experiments","subjectLog.csv"));
    % subjectNames = string(subjectNames.SubjectName);
    subjectNames = string(categorize(fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Subjects"),'isDir'));
    
    % if strcmp(getenv("COMPUTERNAME"),'DESKTOP-MRI7THQ') % PRIMUS SPECIAL CASE
    %     localPath = fullfile(params.paths.projDir_local);
    % else
    %     localPath = fullfile(params.paths.projDir_local, "Experiments",params.extractCfg.experiment,modality);
    % end
    % localPath = fullfile(params.paths.projDir_local, "Experiments",params.extractCfg.experiment,modality);
    localPath = fullfile(params.paths.rawData.(modality).local);
    
    % cloudPath = fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Data","Raw-Data",modality);
    cloudPath = fullfile(params.paths.rawData.(modality).cloud);
    % localPath = rawDataPaths.local;
    % cloudPath = rawDataPaths.cloud;
    localDataDir = [];
    cloudDataDir = [];
    for i = 1:length(subjectNames)
        subjName = subjectNames{i};
        if ~isempty(localPath)
            localDataDir = [localDataDir; dataDir(localPath, subjName)];
        end
        if ~isempty(cloudPath)
            cloudDataDir = [cloudDataDir; dataDir(cloudPath, subjName)];
        end
    end
    modalDataDir = [localDataDir; cloudDataDir];
    sessionNames = regexprep(string(unique({modalDataDir.name})'),'\..*$','');
    % update extraction log
    extractionLog = table;    
    extractionLog.SessionName = sessionNames;
    extractionLog.Extracted = zeros(size(sessionNames));
    extractionLog.TrialMask = repelem("--",size(sessionNames,1))';        
    switch ftype
        case 'csv'
            write(extractionLog,fullfile(params.paths.projDir_cloud,"Experiments",params.extractCfg.experiment,"Extraction-Logs",sprintf("%s_extraction_log.csv",modality)))
        case 'mat'
            save(fullfile(params.paths.all_data_path,"Extraction-Logs",sprintf("%s_extraction_log.mat",modality)),'extractionLog');
    end
    
    
end