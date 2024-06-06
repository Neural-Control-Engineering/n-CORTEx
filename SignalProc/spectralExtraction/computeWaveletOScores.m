function [lPRE, lPOST, rPRE, rPOST, P] = computeWaveletOScores(bands, dts)    
    lCond = ~contains(dts.sessionLabel,"R-hind-paw") & ~contains(dts.sessionLabel,"spontaneous");
    rCond = ~contains(dts.sessionLabel,"L-hind-paw") & ~contains(dts.sessionLabel,"spontaneous");
    spntCond = ~contains(dts.sessionLabel,"R-hind-paw") & ~contains(dts.sessionLabel,"L-hind-paw");
    lDTS = dts(lCond,:);
    rDTS = dts(rCond,:);
    spntDTS = dts(spntCond,:);
    bandNames = fieldnames(bands);
    lfpPreSamp = 1750;
    lfpFs = 500;
    lPRE = [];
    lPOST = [];    
    rPRE = [];
    rPOST = [];
   
    for i = 1:height(lDTS)

        lfp = lDTS.lfp{i}; 
        lfp = lfp(1:384,:);

        pre = zeros(size(lfp,1),length(bandNames));
        post = zeros(size(lfp,1),length(bandNames));
        for j = 1:size(lfp,1)
            chanSelect = j;
            tLfp = ([1:size(lfp,2)] - lfpPreSamp) ./ lfpFs;
            preCond = tLfp < 0;
            postCond = tLfp > 0;
            preLfp = lfp(1:384,preCond);            
            postLfp = lfp(1:384,postCond);
            segSize = min([size(preLfp,2), size(postLfp,2)]);
            preLfp = preLfp(:,1:segSize);
            [preWvs, preFreqs] = cwt(preLfp(chanSelect,:),'morse',500,"TimeBandwidth",25);     
            preWvs = 10*log10(abs(preWvs));
            postLfp = postLfp(:,1:segSize);
            [postWvs, postFreqs] = cwt(postLfp(chanSelect,:),'morse',500,"TimeBandwidth",25);        
            postWvs = 10*log10(abs(postWvs));
    
            highFRange = max(preFreqs) - 50;
            highFSteps = highFRange / 25;
            highFStart = 50;
            for n = 1:highFSteps
                bands.(sprintf("high%d",n)) = [highFStart, highFStart+25];
                highFStart = highFStart + 25;
            end    
            P = {};
            for k = 1:length(bandNames)            
                band = bandNames{k};
                P = [P, band];
                bRange = bands.(band);
                preFCond = preFreqs>bRange(1) & preFreqs < bRange(2);
                postFCond = postFreqs>bRange(1) & postFreqs < bRange(2);
                preWv = preWvs(preFCond,:);
                preAvg = mean(preWv,1);
                preAvg = mean(preAvg,2);
                pre(j,k) = preAvg;    
    
                postWv = postWvs(postFCond,:);
                postAvg = mean(postWv,1);
                postAvg = mean(postAvg,2);
                post(j,k) = postAvg;    
                
    
                % times = ([1:size(W,2)]-1751)./500;
                % plot(ax, times,Wsub,"Color",stnColor); title(ax,sprintf("%s (%d - %d Hz)",band, bRange(1), bRange(2)));
                % xline(ax,times(find(times==tAx)))
            end            
        end
        lPRE = cat(3, lPRE, pre);
        lPOST = cat(3, lPOST, post);
    end

    fh = figure;
    t1 = tiledlayout(1,3);
    title(t1,"Left-hind-paw")
    tAx = nexttile(t1); 
    imagesc(mean(lPRE,3)); caxis(tAx,[-50.56459709605963,-46.346166098559635]);
    title(tAx,"PRE")    
    tAx = nexttile(t1); 
    imagesc(mean(lPOST,3)); caxis(tAx,[-50.56459709605963,-46.346166098559635]);
    title(tAx,"POST")    
    tAx = nexttile(t1); 
    imagesc(mean(lPOST,3)-mean(lPRE,3)); caxis(tAx,[-0.5357779729561683,0.89297928765196])        
    title(tAx,"DIFF")

    for i = 1:height(rDTS)

        lfp = rDTS.lfp{i};
        lfp = lfp(1:384,:);

        pre = zeros(size(lfp,1),length(bandNames));
        post = zeros(size(lfp,1),length(bandNames));
        for j = 1:size(lfp,1)
            chanSelect = j;
            tLfp = ([1:size(lfp,2)] - lfpPreSamp) ./ lfpFs;
            preCond = tLfp < 0;
            postCond = tLfp > 0;
            preLfp = lfp(1:384,preCond);
            postLfp = lfp(1:384,postCond);
            segSize = min([size(preLfp,2), size(postLfp,2)]);
            preLfp = preLfp(:,1:segSize);
            [preWvs, preFreqs] = cwt(preLfp(chanSelect,:),'morse',500,"TimeBandwidth",25);
            preWvs = 10*log10(abs(preWvs));
            postLfp = postLfp(:,1:segSize);
            [postWvs, postFreqs] = cwt(postLfp(chanSelect,:),'morse',500,"TimeBandwidth",25);
            postWvs = 10*log10(abs(postWvs));

            highFRange = max(preFreqs) - 50;
            highFSteps = highFRange / 25;
            highFStart = 50;
            for n = 1:highFSteps
                bands.(sprintf("high%d",n)) = [highFStart, highFStart+25];
                highFStart = highFStart + 25;
            end
            P = {};
            for k = 1:length(bandNames)
                band = bandNames{k};
                P = [P, band];
                bRange = bands.(band);
                preFCond = preFreqs>bRange(1) & preFreqs < bRange(2);
                postFCond = postFreqs>bRange(1) & postFreqs < bRange(2);
                preWv = preWvs(preFCond,:);
                preAvg = mean(preWv,1);
                preAvg = mean(preAvg,2);
                pre(j,k) = preAvg;

                postWv = postWvs(postFCond,:);
                postAvg = mean(postWv,1);
                postAvg = mean(postAvg,2);
                post(j,k) = postAvg;


                % times = ([1:size(W,2)]-1751)./500;
                % plot(ax, times,Wsub,"Color",stnColor); title(ax,sprintf("%s (%d - %d Hz)",band, bRange(1), bRange(2)));
                % xline(ax,times(find(times==tAx)))
            end
        end
        rPRE = cat(3, rPRE, pre);
        rPOST = cat(3, rPOST, post);
    end

    fh = figure;
    t1 = tiledlayout(1,3);
    title(t1,"Right-hind-paw")
    tAx = nexttile(t1); 
    imagesc(mean(rPRE,3)); caxis(tAx,[-50.56459709605963,-46.346166098559635]);
    title("PRE")
    tAx = nexttile(t1); 
    imagesc(mean(rPOST,3)); caxis(tAx,[-50.56459709605963,-46.346166098559635]);
    title("POST")
    tAx = nexttile(t1); 
    imagesc(mean(rPOST,3)-mean(rPRE,3)); caxis(tAx,[-0.5357779729561683,0.89297928765196])        
    title("DIFF")

end