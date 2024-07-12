function [pre, post, P] = computeWaveletScores(params, lfpGroup, tEvent)
    
    bands = params.bands;
    % Augment Band ranges
    % highFRange = max(preFreqs) - 50;
    highFRange = 200;
    highFSteps = highFRange / 25;
    highFStart = 50;
    for n = 1:highFSteps
        bands.(sprintf("high%d",n)) = [highFStart, highFStart+25];
        highFStart = highFStart + 25;
    end    
    bandNames = fieldnames(bands);

    PRE = [];
    POST = [];
   
    for i = 1:height(lfpGroup)
        disp(i);
        lfp = lfpGroup.lfp{i}; 
        if ~isempty(lfp)
            tEvnt = tEvent{i};
            lfp = lfp(1:384,:);
            pre = zeros(size(lfp,1),length(bandNames));
            post = zeros(size(lfp,1),length(bandNames));
            for j = 1:size(lfp,1)
                chanSelect = j;
                % tEvent = ([1:size(lfp,2)] - lfpPreSamp) ./ lfpFs;
                % disp(j);
                preCond = tEvnt < 0;
                postCond = tEvnt > 0;
                preLfp = lfp(1:384,preCond);
                postLfp = lfp(1:384,postCond);
                segSize = min([size(preLfp,2), size(postLfp,2)]);
                preLfp = preLfp(:,1:segSize);
                [preWvs, preFreqs] = cwt(preLfp(chanSelect,:),'morse',500,"TimeBandwidth",25);
                preWvs = 10*log10(abs(preWvs));
                postLfp = postLfp(:,1:segSize);
                [postWvs, postFreqs] = cwt(postLfp(chanSelect,:),'morse',500,"TimeBandwidth",25);
                postWvs = 10*log10(abs(postWvs));                      
                % BAND-WISE AVERAGING
                P = {};
                for k = 1:length(bandNames)
                    band = bandNames{k};
                    P = [P, band];
                    bRange = bands.(band);
                    preFCond = preFreqs>bRange(1) & preFreqs < bRange(2);
                    postFCond = postFreqs>bRange(1) & postFreqs < bRange(2);
                    % Pre avging
                    preWv = preWvs(preFCond,:);
                    preAvg = mean(preWv,1);
                    preAvg = mean(preAvg,2);
                    pre(j,k) = preAvg;
                    % Post avging
                    postWv = postWvs(postFCond,:);
                    postAvg = mean(postWv,1);
                    postAvg = mean(postAvg,2);
                    post(j,k) = postAvg;                             
                end
            end
            PRE = cat(3, PRE, pre);
            POST = cat(3, POST, post);
        end
    end
end