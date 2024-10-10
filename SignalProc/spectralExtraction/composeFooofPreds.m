function fooofPsds = composeFooofPreds(fooofPredictions, f, numPeaks, psdLen)
    % fooofPsds = zeros(size(fooofPredictions,1),psdLen);
    fooofPsds = cell(size(fooofPredictions,1),1);
    preds = gpuArray(fooofPredictions);
    parfor i = 1:size(fooofPsds,1)
        pred = preds(i,:);
        OFF = pred(1);
        EXP = pred(2);
        sig = log10(1./(f.^EXP))+OFF;
        for j = 1:numPeaks
            % extract predictions
            peakPtr = (j)*3;
            idx_CF = peakPtr;
            idx_PW = peakPtr+1;
            idx_BW = peakPtr+2;
            CF = pred(idx_CF);
            PW = pred(idx_PW);
            BW = pred(idx_BW);
            % compose into signal            
            G = PW * exp(-(f - CF).^2 / (2 * BW^2));
            % add each peak
            sig = sig + (G);
       end
       fooofPsds{i} = sig;
    end
    fooofPsds = gather(cat(1, fooofPsds{:}));
end