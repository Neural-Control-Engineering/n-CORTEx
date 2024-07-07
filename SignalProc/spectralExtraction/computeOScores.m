function [oscPRE, oscPOST, mPRE, mPOST, P] = computeOScores(params, lfpGroup, tEvent)
    
    bands = params.bands;
    % Augment Band ranges
    % highFRange = max(preFreqs) - 50;
    % highFRange = 200;
    % highFSteps = highFRange / 25;
    % highFStart = 50;
    % for n = 1:highFSteps
    %     bands.(sprintf("high%d",n)) = [highFStart, highFStart+25];
    %     highFStart = highFStart + 25;
    % end    
    bandNames = fieldnames(bands);

    PRE = [];
    mPRE = [];
    POST = [];
    mPOST = [];

    for i = 1:height(lfpGroup)
        % disp(i)
        lfp = lfpGroup.lfp{i};
        if ~isempty(lfp)
            tEvnt = tEvent{i};
            lfp = lfp(1:384,:);
            pre = zeros(size(lfp,1),length(bandNames));
            post = zeros(size(lfp,1),length(bandNames));
            % EVENT-WISE SEGMENTATION
            preCond = tEvnt < 0;
            postCond = tEvnt > 0;
            lfpPRE = lfp(1:384,preCond);
            lfpPOST = lfp(1:384,postCond);
            segSize = min([size(lfpPRE,2), size(lfpPOST,2)]);
            lfpPRE = lfpPRE(:,1:segSize);
            lfpPOST = lfpPOST(:,1:segSize);
            % FOOOF / SpecParams
            freqsPRE = fooof(params, lfpPRE);
            freqsPOST = fooof(params, lfpPOST);
            [Spre, P, maskPRE] = binFooofParams(bands, freqsPRE.fooofparams);
            [Spost, P, maskPOST] = binFooofParams(bands, freqsPOST.fooofparams);
            maskPRE = cMap2Regions(maskPRE, params.regMap);
            maskPOST = cMap2Regions(maskPOST, params.regMap);
            % O-Scoes
            % % BINARY MASK
            % if mod(i,10)==0 && tCnt <= (196)
            % 
            %     % nexttile(th); image(cmaskPRE); title(sprintf("PRE--t%s--%s",tNum, date));
            %     nexttile(th); image(cmaskPOST); title(sprintf("POST--t%s--%s",tNum, date));
            %     nexttile(th); imagesc(freqsPRE.freq,[1:384],10*log10(freqsPRE.powspctrm)); title("PRE");
            %     nexttile(th); imagesc(freqsPOST.freq,[1:384],10*log10(freqsPOST.powspctrm)); title("POST")
            %     tCnt = tCnt+4;
            % end
            % figure
            % t = tiledlayout(2,2); nexttile;
            % imagesc(freqsPRE.freq,[1:384],10*log10(freqsPRE.powspctrm)); title("PRE"); nexttile;
            % imagesc(freqsPOST.freq,[1:384],10*log10(freqsPOST.powspctrm)); title("POST"); nexttile;
            % imagesc(maskPRE); title("PRE"); nexttile;
            % imagesc(maskPOST); title("POST"); title(t,"CF binary mask");
            PRE = cat(3, PRE, table2cell(Spre));
            mPRE = cat(3, mPRE, maskPRE);
            POST = cat(3, POST, table2cell(Spost));
            mPOST = cat(3, mPOST, maskPOST);

            oscPRE = computeOscillationScore(bands, P, PRE);
            oscPOST = computeOscillationScore(bands, P, POST);
        end     
    end
end


% plotOScores(oscPRE,"PRE");
% 
% plotOScores(oscPOST,"POST");
% oscSPONT = computeOscillationScore(bands, P, SPONT);
% plotOScores(oscSPONT,"SPONT");
% 
% % GROUP CHANNELS FOR BARS
% plotSGBars(regMap,P,{SPONT, PRE, POST},["SPONT","PRE","POST"], 'channel');
