function  STAT_join = nexOp_fuseGroups(STAT, groupIDCols)
    % combine df col elements into multi-dimensional dataframes along
    % fusable axes
    % groupIDs : groups to keep separate

    [G_fuse, groups] = findgroups(STAT.(groupIDCols));
    % G_trial = findgroups(STAT.trialNumber);
    % pair within fusing groups (using trialNumber - this has already been
    % segregated in nexOp_compileSTAT)
    STAT_struct = table2struct(STAT);
    STAT_join = splitapply(@(group) nexOp_joinSamples(group), STAT_struct, G_fuse);
    % TEMPORARY (only one group used)
    STAT_join = STAT_join{1};


end