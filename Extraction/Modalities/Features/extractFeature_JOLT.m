function extractFeature_JOLT(params, dataStore)
    
    % extract LFP features to a labeled classifier dataset from datastore
    % 1) split spontaneous trials into T second samples, length equivalent
    % to stim-associated trials
    % 2) extract items: PSD, SpecParams, rawLFP, etc.
    % 3) append to row, mark 'Extracted'
    % 4) append to datastore
    
    % ft_startup;

    % CONDITIONING
    dataStore.responseDelay = cellfun(@(x) replaceNaN(x,-1), dataStore.responseDelay, "UniformOutput",false);
    dataStore.responseThreshold = cellfun(@(x) replaceNaN(x,-1), dataStore.responseThreshold, "UniformOutput",false);
    
    %% DEFINE
    TRIAL_DURATION = 5;
    MAX_SESSION_DURATION = 35 * 60; % 35 minutes converted to seconds
    LFP_FS = params.extractCfg.LFP.Fs;
    LFP_DWNSMP = params.extractCfg.LFP.downSamp;    
    NUMPROBE = params.extractCfg.npxls.numProbes;    
    NUMCHAN = 384;
    NSPONT = 20;

    extractionLog = readtable(fullfile(params.paths.projDir_cloud, "Experiments", params.extractCfg.experiment, "Extraction-Logs", "Feature_extraction_log.csv"),"Delimiter",",");    
    subjectLog = readtable(fullfile(params.paths.projDir_cloud,"Experiments", "subjectLog.csv"),"Delimiter",",");
    numSessionsToExtract = height(extractionLog);
    numTrialLfpSamps = (LFP_FS / LFP_DWNSMP) * TRIAL_DURATION;
    maxLfpSamps = (LFP_FS / LFP_DWNSMP) * MAX_SESSION_DURATION;
    % sampStep = round(MAX_SESSION_DURATION / TRIAL_DURATION )*NUMCHAN;
    sampStep = NUMCHAN * NSPONT;
    lfp_fs = LFP_FS / LFP_DWNSMP;
    
    %% INIT COLUMNS
    cellInit = cell((numSessionsToExtract)*sampStep,1);      
    varNames = dataStore.Properties.VariableNames;

    lfpCols = varNames(contains(varNames, 'LFP'));   
    psdVars = {"psdMacro","psdMicro"}; 
    bands = fieldnames(params.bands);
    lfpVars = suffixFeatures(psdVars,bands);
    lfpVars = ["lfp", lfpVars];
    lfpFeatures = prefixFeatures(lfpVars, lfpCols); 
    labels = {"channel","day","pawSide","SNI","responseDelay","responseThreshold"};    
    colNames = [labels, lfpFeatures];  
    dataCols = struct;
    
    for i = 1:length(colNames)
        colName = colNames{i};
        dataCols.(colName) = cellInit;
    end       
    
    %% ITERATE    
    for i = 1:height(dataStore)        

        
        disp(i);
        sessionData = dataStore(i,:);
        ftrs = struct;
             
        % LFP FEATURES
        for j = 1:length(lfpCols)                       

            lfpCol = lfpCols{j};
            colTag = split(lfpCol,'_');
            colTag = colTag{2,1};
            lfp_raw = sessionData.(lfpCol);
            lfpMat = lfp_raw{1};
            lfpMat = lfpMat(1:384,:);  
            
            lfpMat = truncTnsr(lfpMat, numTrialLfpSamps*NSPONT, 2);           
        
           %% SEGMENT AND SEPARATE
            % break into segments/trials
            data_seg = segmentSeries(lfpMat, numTrialLfpSamps, 2);
            [lfp, chan_lfp] = cellfun(@(x) unstackMat(x), data_seg, 'UniformOutput', false);
            ftrs.lfp = cat(1,lfp{:});
            channel = cat(1,chan_lfp{:});
            M = size(ftrs.lfp,1);           
            % Recover spectral power (macro)
            [psdMacro, f_macro, t_macro] = cellfun(@(x) multiSpectrogram(x, lfp_fs, 370, 185, 1), data_seg, 'UniformOutput', false);      
            [psdMacro, b_macro] = cellfun(@(x, f) squeezeBands(params.bands, x, f, 1), psdMacro, f_macro, 'UniformOutput', false);      
            psdMacro = cellfun(@(x) 10*log10(abs(x)), psdMacro, 'UniformOutput',false);
            psdMacro = cellfun(@(x) permute(x,[3,2,1]), psdMacro, 'UniformOutput', false);
            psdMacro_bands = cellfun(@(x) mat2cell(x, ones(1,size(x,1)), size(x,2), ones(1,size(x,3))), psdMacro, 'UniformOutput', false);             
            ftrs.psdMacro = cat(1,psdMacro_bands{:});
            % spectral power (2 ms time bins, micro)
            [psdMicro, f_micro, t_micro] = cellfun(@(x) multiSpectrogram(x, lfp_fs, 80, 79, 1), data_seg, 'UniformOutput', false);            
            [psdMicro, b_micro] = cellfun(@(x, f) squeezeBands(params.bands, x, f, 1), psdMicro, f_micro, 'UniformOutput', false);      
            psdMicro = cellfun(@(x) 10*log10(abs(x)), psdMicro, 'UniformOutput',false);
            psdMicro = cellfun(@(x) permute(x,[3,2,1]), psdMicro, 'UniformOutput', false);
            psdMicro_bands = cellfun(@(x) mat2cell(x, ones(1,size(x,1)), size(x,2), ones(1,size(x,3))), psdMicro, 'UniformOutput', false);             
            ftrs.psdMicro = cat(1,psdMicro_bands{:});            

           %% PHASE COUPLING

           %% SPECPARAMS
            % data_specPrm = cellfun(@(x) specParamGram(x), 'UniformOutput', true);
            % convert to ft structure
            % data_ft = raw2ft(params, data_seg, lfp_fs);
            % data_ft = ft_preprocessing(params.ftCfg_preproc, data_ft);   

            for k = 1:length(lfpFeatures)
                % ASSIGN
                lfpFtr = lfpFeatures{k};
                lfpVar = lfpVars(k);
                if contains(lfpFtr,lfpCol)                                       
                    if contains(lfpVar,string(psdVars))                        
                        psdVar = string(psdVars(matches(string(psdVars),string(split(lfpVar,'_')))));
                        band = split(lfpVar,'_'); band = band(end);
                        bandIdx = strcmpi(band, bands);
                        col = sprintf("%s_%s",lfpCol,lfpVar);                        
                        psd = ftrs.(psdVar);                            
                        dataCols.(col){i} = psd(:,:,bandIdx);                      
                    else   
                        col = sprintf("%s_%s",lfpCol, lfpVar);          
                        dataCols.(col){i} = ftrs.(lfpVar);          
                    end                    
                end
            end     
        end

        % AP FEATURES
      
        % SESSION FEATURES / LABELS 
        lbls = struct;
        lbls.channel = channel;
        % Response delay        
        lbls.responseDelay = num2cell(repelem(cell2mat(sessionData.responseDelay),M))';
        % Response threshold        
        lbls.responseThreshold = num2cell(repelem(cell2mat(sessionData.responseThreshold),M))';
        % Paw side (Left / 1 OR Right / 2 OR Spont / 3)
        pawside = encodePawSide(sessionData.pawSide);   
        lbls.pawSide = num2cell(repelem(pawside,M))';
        % Day
        dateSNI = subjectLog(string(subjectLog.SubjectName) == string(sessionData.subjectName),:).dateSNI;
        day = encodeDay(datetime(string(sessionData.date),"Format","uuuu-MM-dd"), dateSNI);
        lbls.day = num2cell(repelem(day,M))';
        % SNI
        % sni = encodeSNI(sessionData.SNI);                  
        lbls.SNI = num2cell(repelem(-1,M))';
     
        %% COLUMN ASSIGNMENTS
        for j = 1:length(labels)
            label = labels{j};
            % dtaCol = dataCols.(label);
            dataCols.(label){i} = lbls.(label);
            % cmd = sprintf("%s(ptr:ptr+M-1) = %s;",label, lower(label));
            % cmd = sprintf("%s{ptr} = %s;",label, lower(label));
            % eval(cmd);
            % evalin('base',cmd);
        end               

    end

    %% EXPORT (TO HDF5) ^^^^ 
    dataFields = fieldnames(dataCols);
    dataTable = table();
    for i = 1:length(dataFields)
        dtaField = dataFields{i};
        dataCol = dataCols.(dtaField);
        dataCol = cat(1,dataCol{:});
        dataTable.(dtaField) = dataCol;
    end

    % Specify the filename
    hdf5Filename = fullfile(params.paths.projDir_cloud, "Experiments", params.extractCfg.experiment, "Data", "Labeled-Data", 'features.h5');
    
    % Export the table to HDF5
    writetable(dataTable, 'temp.csv');  % Write to a temporary CSV file
    hdf5write(hdf5Filename, 'data', 'temp.csv');  % Write CSV data to HDF5
    
    % Clean up: delete the temporary CSV file
    delete('temp.csv');

end