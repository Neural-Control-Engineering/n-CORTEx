function trainIdxs = nexStat_allocateFolds(stratVar, numFolds)
    % return sample indices for N folds 
    % each fold will be shuffled, independent
    % sampleIdxs = [1:height(STAT)]';
    % sampleIdxs_shuffle = randperm(height(STAT))';  
    % idx_fold = ceil(sampleIdxs * numFolds / length(sampleIdxs));
    % sampleIdxs = splitapply(@(smpIDX) {smpIDX}, sampleIdxs_shuffle, idx_fold);
    % switch class(stratVar)
    %     case "string"
    %         stratVar=
    %     case
    % end
    cv = cvpartition(stratVar, 'KFold', numFolds);
    for k = 1:numFolds
        trainIdxs{k} = (training(cv,k));
        % testIdx{k}  = (test(sampleMasks,k));
    end
end