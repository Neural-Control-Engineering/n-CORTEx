function nex_exportLabeledSet(nexon, dfIDs, labelIDs, segmentFcn)    
    numDtsRows = height(nexon.console.BASE.DTS);
    NUMFOLDS = 5;    
    numSamplesPerFold = floor(numDtsRows / NUMFOLDS);
    % enumerate/encode labels
    labelKeys = nex_enumerateSessionLabels(nexon, labelIDs);
    % visit each exported data column
    for i=1:length(dfIDs)
        % visit each row
        dfID = dfIDs(i);
        minLen = nex_getDfMinLength(nexon, dfID);
        batchPath = fullfile(nexon.console.BASE.params.paths.Data.FTR.local,"TRAIN",dfID,"Batch");
        A_lbl = [];
        A_fileTag = [];
        A_foldID = [];
        X = [];
        Y = [];
        m=1;
        for j=1:numDtsRows                      
            sample = grabDataFrame(nexon, dfID, j);
            % skip empty samples
            if ~isempty(sample)
                % fold number 
                foldNum = floor(m/numSamplesPerFold)+1;
                foldID = sprintf("Fold%d",foldNum);
                % truncate each sample to overall minlength (that isnt 0 or
                % empty)
                sample = sample(:,1:minLen);
                % write each sample to a csv
                sampleTag = sprintf("%0*d.csv",10,m);                        
                sessionLabel = grabDataFrame(nexon,"sessionLabel",j);
                labels = arrayfun(@(x) parseSessionLabel(sessionLabel,x), labelIDs,"UniformOutput",true);
                % amend labels with labelID letter prefixes or hyphens
                amendCond = arrayfun(@(x) isStartsWithDigit(x), labels, "UniformOutput",true);
                labels(amendCond) = strcat(extractBefore(labelIDs(amendCond),2),labels(amendCond));
                labels_underscore = strrep(labels,"-","_");
                labelVals = arrayfun(@(x,y) labelKeys.(x).(y), labelIDs, labels_underscore,"UniformOutput",true)';
                % write sample to designated location
                samplePath = fullfile(batchPath,foldID);
                buildPath(samplePath);
                writematrix(sample,fullfile(samplePath,sampleTag));      
                % A (sample index)
                A_lbl = [A_lbl; labelVals]; 
                A_foldID = [A_foldID; foldID];
                A_fileTag = [A_fileTag; sampleTag];
                % sample channel breakout + labeling
                chans = [1:size(sample,1)]';
                labelVals_exp = repmat(labelVals,size(sample,1),1); % expand channel breakout labels to also include general labels
                y = [chans, labelVals_exp];
                X = [X; sample];
                Y = [Y; y];
                % increment counter
                m=m+1;
            end
        end
        datasetPath = fullfile(nexon.console.BASE.params.paths.Data.FTR.local,"TRAIN",dfID);
        % write A
        A = [A_fileTag, A_foldID, A_lbl];                
        % Convert to table with column headers
        columnNames = [{'fileTag', 'foldID'}, labelIDs']; % Define your column names
        A_table = array2table(A, 'VariableNames', columnNames);        
        writetable(array2table(A),fullfile(batchPath,"index.csv"));
        % write X / Y
        % x_colNames = "sample"; 
        y_colNames = [{'channel'}, labelIDs'];
        % X_table = array2table(X,'VariableNames',x_colNames);
        Y_table = array2table(Y,'VariableNames',y_colNames);
        writematrix(X,fullfile(datasetPath,"X.csv"));
        writetable(Y_table,fullfile(datasetPath,"Y.csv"));
        % save labelKey 
        exportLabelKeys(labelKeys, fullfile(datasetPath,"labelKeys.json"));
    end
end