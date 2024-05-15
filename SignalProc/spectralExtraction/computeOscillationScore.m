function osc = computeOscillationScores(bands, P, SG)
    % INPUT:
    % P :  fooof params column identifiers
    % SG : specs grouping for computing oscillation score
    % bands : parametric canoninical bands and their ranges
    
    % OUTPUT:
    % osc : struct containing oscillation scores, power map, probability map

    osc.powerMap = []; % per param
    osc.probabilityMap = []; % 
    osc.scores = []; % 
    osc.bandLabels = [];
    bandNames = fieldnames(bands);
    for i = 1:length(bandNames)
        band = bandNames{i};
        tagPW = sprintf("%s_PW",band);
        tagIdx = find(strcmp(string(P),tagPW));
        bandGroup = SG(:,tagIdx,:);
        bandGroup = squeeze(bandGroup);        
        bgMat = cell2mat(bandGroup);
        % osc probabilities 
        isPW = ~isnan(bgMat);
        probs = sum(isPW,2) ./ size(isPW,2);
        % avg powers / normalized
        avgPW = mean(bgMat,2,"omitnan");
        maxPW = max(avgPW);
        normPW = avgPW ./ maxPW;
        % o-scores (oscillation scores)
        score = normPW .* probs;
        % assign outputs
        osc.powerMap = [osc.powerMap, normPW];
        osc.probabilityMap = [osc.probabilityMap, probs];
        osc.scores = [osc.scores, score];
        osc.bandLabels = [osc.bandLabels, string(band)];
    end
end