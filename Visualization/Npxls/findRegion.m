function reg = findRegion(probeRegs, y)
    yRegStart = probeRegs.probe_tip_distance(:,2);
<<<<<<< Updated upstream
=======
    % yRegStart = probeRegs.probe_depth(:,2);
>>>>>>> Stashed changes
    ydif = yRegStart - y/1000;    
    ydif_neg = ydif(ydif<0);
    ydif_neg_min = max((ydif_neg));
    i_reg = find(ydif == ydif_neg_min);
    reg = probeRegs(i_reg,:);
end