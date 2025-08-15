function firstTrials = findFirstTrials(trial_starts, gate_starts)
    segs = discretize(trial_starts,gate_starts);
    % splitapply(trial_starts,segs)
    firstTrials = splitapply(@(x) min(x),trial_starts,segs);
end 