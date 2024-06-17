function reg = findRegion(probeRegs, y)
    yRegStart = probeRegs.probe_tip_distance(:,2);
    % yRegStart = probeRegs.probe_depth(:,2);
    ydif = yRegStart - y/1000;    
    ydif_neg = ydif(ydif<0);
    ydif_neg_min = max((ydif_neg));
    i_reg = find(ydif == ydif_neg_min);
    reg = probeRegs(i_reg,:);
end