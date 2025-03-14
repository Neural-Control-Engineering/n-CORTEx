function plotOScores_legacy(osc,ttl)    
    figure    
    t = tiledlayout(1,3)
    nexttile
    imagesc(osc.scores);
    title("OScores");
    nexttile
    imagesc(osc.powerMap);
    title("Normalized PW")
    nexttile
    imagesc(osc.probabilityMap);
    title("Probability Map");
    colorbar;
    title(t,ttl)
end