function writeSpecs2Torch(T, F, freq, saveDir)
    PADLEN = 26;
    NUMFOLDS = 5;
    if isempty(freq)
        freq = T(1,:).fooofparams{1};
        freq_default= freq.freq;
    else
        freq_default=freq;
    end
    
    % load specsData table containing fooofParams and validated spectral
    % fits
    if isempty(T)
        load(fullfile(labelDir,"labels.mat"));    
    end    
    % Fold Partitioning
    numSamples = (height(T) - 9625) + 9625 * 2; % using augmented samples (PMT)
    partitionCount = floor(numSamples / NUMFOLDS);
    pCounter = 1;

    A_lbl = [];
    A_fileTag = [];
    A_foldID = [];
    % write annotated csv with format 
    m=1;
    for i =1:height(T)        
        sampleLabel = T(i,:).sampleLabel;
        sampleType = T(i,:).sampleType;
        if ~strcmp(sampleLabel,"")
            trialNum = str2double(parseSessionLabel(sampleLabel,"trialNum"));
            chanNum = str2double(parseSessionLabel(sampleLabel,"chanNum"));
            gIdx = strfind(sampleLabel,"g0");
            sessionLabel = char(sampleLabel);
            sessionLabel = string(sessionLabel(1:gIdx+1));
            % retrieve corresponding PMT  (from F)
            sessionRow = F(contains(F.sessionLabel,sessionLabel) & ismember(F.trialNum,trialNum),:);
            specs = sessionRow.fooofparams{1};
            specs = specs(chanNum,:);
        else
            trialNum = [];
            chanNum = [];
            specs = T(i,:).fooofparams{1};
        end
        
        try
            PMT = sessionRow.powspctrm_pmt{1};
            PMT = PMT(:,chanNum);
            pmtCond = [1:size(specs.power_spectrum,2)];        
            pmt_sample = log10(PMT(pmtCond))';
        catch e
            pmt_sample = [];
        end
        psd_sample = specs.power_spectrum;
        try
            freq = specs.freq;
        catch
            freq = freq_default;
        end
        % figure; plot(pmt_sample);
        % hold on
        % plot(psd_sample)
        % plot(log10(PMT(pmtCond)));
        % plot(specs.power_spectrum);
        % plot(log10(specs.fooofed_spectrum));
        % save pmt as odd sample, psd as even sample, both labeled with
        % fooofparams / label formatting
        apParams = specs.aperiodic_params;
        peakParams = specs.peak_params;
        peakParams = sortrows(peakParams);
        lblRow = [];
        lblRow = [lblRow, apParams];        
        for j = 1:size(peakParams,1)
            lblRow = [lblRow, peakParams(j,:)];
        end
        % pad right to 32 places
        padLen = PADLEN - size(lblRow,2);
        lblRow = [lblRow, zeros(1,padLen)];
        switch sampleType
            case "Verified"
                for j = 1:2            
                    fileTag = sprintf("%0*d.csv",10,m);                        
                    if mod(m,2) == 0 % if even use PSD
                        sampleData = [freq', psd_sample'];
                    elseif mod(m,2) == 1 % if odd use PMT
                        sampleData = [freq', pmt_sample'];
                    end
                    % append corresponding label for both PSD and PMT (they should
                    % be identical)
                    
                    % Save sample data as csv
                    T_sample = array2table(sampleData);
                    T_sample.Properties.VariableNames={'Frequency','PSD'};
                    % foldNum = mod(m, partitionCount)
                    foldNum = ceil(m / partitionCount);            
                    sampleSavePath = fullfile(saveDir,sprintf("Fold%d",foldNum));
                    buildPath(sampleSavePath);
                    writetable(T_sample,fullfile(sampleSavePath,fileTag));
                    % APPEND ANNOTATIONS
                    A_lbl = [A_lbl; lblRow]; 
                    A_foldID = [A_foldID; sprintf("Fold%d",foldNum)];
                    A_fileTag = [A_fileTag; fileTag];
                    m=m+1;
                end      
            case "Corrected"
                for j = 1:2            
                    fileTag = sprintf("%0*d.csv",10,m);                        
                    if mod(m,2) == 0 % if even use PSD
                        sampleData = [freq', psd_sample'];
                    elseif mod(m,2) == 1 % if odd use PMT
                        sampleData = [freq', pmt_sample'];
                    end
                    % append corresponding label for both PSD and PMT (they should
                    % be identical)
                    
                    % Save sample data as csv
                    T_sample = array2table(sampleData);
                    T_sample.Properties.VariableNames={'Frequency','PSD'};
                    % foldNum = mod(m, partitionCount)
                    foldNum = ceil(m / partitionCount);            
                    sampleSavePath = fullfile(saveDir,sprintf("Fold%d",foldNum));
                    buildPath(sampleSavePath);
                    writetable(T_sample,fullfile(sampleSavePath,fileTag));
                    % APPEND ANNOTATIONS
                    A_lbl = [A_lbl; lblRow]; 
                    A_foldID = [A_foldID; sprintf("Fold%d",foldNum)];
                    A_fileTag = [A_fileTag; fileTag];
                    m=m+1;
                end      
            case "Synthetic"
                fileTag = sprintf("%0*d.csv",10,m);             
                sampleData = [freq', psd_sample'];
                % Save sample data as csv
                T_sample = array2table(sampleData);
                T_sample.Properties.VariableNames={'Frequency','PSD'};
                % foldNum = mod(m, partitionCount)
                foldNum = ceil(m / partitionCount);            
                sampleSavePath = fullfile(saveDir,sprintf("Fold%d",foldNum));
                buildPath(sampleSavePath);
                writetable(T_sample,fullfile(sampleSavePath,fileTag));
                % APPEND ANNOTATIONS
                A_lbl = [A_lbl; lblRow]; 
                A_foldID = [A_foldID; sprintf("Fold%d",foldNum)];
                A_fileTag = [A_fileTag; fileTag];
                m=m+1;
        end

    end
    A = [A_fileTag, A_foldID, A_lbl];
    writetable(array2table(A),fullfile(saveDir,"index.csv"));
end