function extractLFPFeature_JOLT(params, dataStore, subject, sessionsToExtract)
    % extract LFP features to a labeled classifier dataset from datastore
    % 1) split spontaneous trials into T second samples, length equivalent
    % to stim-associated trials
    % 2) extract items: PSD, SpecParams, rawLFP, etc.
    % 3) append to row, mark 'Extracted'
    % 4) append to datastore
    
    extractionLog = readTable(fullfile(params.paths.projDir_cloud, "Experiments", params.extractCfg.experiment, "Extraction-Logs", "LFP-Feature_extraction_log.csv"));
    numProbes = params.extractCfg.npxls.numProbes;
    
    %% INIT COLUMNS
    cellInit = cell(length(sessionsToExtract)*4000,1);
    features = {'LFP','PSD','responseDelay','responseThreshold'};
    labels = {'channel', 'session','day','paw-side','SNI'};
    colNames = [labels, features];

    for i = 1:length(sessionsToExtract)

        isSpont = strcmp(dataStore.pawSide{i},'spontaneous');

        switch isSpont
            case  1
                % BREAK SPONTANEOUS LFP INTO 30 sec trials
            case 0
                % 
        end
        
        % LFP

        % PSD

        % R-delay

        % R-thresh

    end

end