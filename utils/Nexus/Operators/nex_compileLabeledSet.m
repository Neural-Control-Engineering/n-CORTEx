function [X, Y] = nex_compileLabeledSet(nexon, dfID, labelIDs, segmentFcn)
    numDtsRows = height(nexon.console.BASE.DTS);
    minLen = nex_getDfMinLength(nexon, dfID);
    X = [];
    Y = [];
    m=1;
    % enumerate/encode labels
    labelKeys = nex_enumerateSessionLabels(nexon, labelIDs);
    for i = 1:numDtsRows
        sample = grabDataFrame(nexon, dfID, i);
        % skip empty samples
        if ~isempty(sample)         
            % truncate each sample to overall minlength (that isnt 0 or
            % empty)
            sample = sample(:,1:minLen);
            % write each sample to a csv           
            sessionLabel = grabDataFrame(nexon,"sessionLabel",i);
            labels = arrayfun(@(x) parseSessionLabel(sessionLabel,x), labelIDs,"UniformOutput",true);
            % amend labels with labelID letter prefixes or hyphens
            amendCond = arrayfun(@(x) isStartsWithDigit(x), labels, "UniformOutput",true);
            labels(amendCond) = strcat(extractBefore(labelIDs(amendCond),2),labels(amendCond));
            labels_underscore = strrep(labels,"-","_");
            labelVals = arrayfun(@(x,y) labelKeys.(x).(y), labelIDs, labels_underscore,"UniformOutput",true)';            
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
end