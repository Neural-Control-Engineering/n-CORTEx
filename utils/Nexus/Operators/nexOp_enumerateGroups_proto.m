function [Y, G] = nexOp_enumerateGroups_proto(Y, groupVars)    
    
    groupVars=strrep(groupVars,"--","_");
    groupIdx = find(ismember(Y.Properties.VariableNames,groupVars));
    Y_groups = Y(:,groupIdx);
    % Primary sorting/grouping
    G = findgroups(Y);
    [G_sort, idx_sort] = sort(G);
    Y_sort=Y(idx_sort,:);
    % Groupvar sorting/grouping
    [G_groups] = findgroups(Y_groups);    
    splitapply(@(g) {(1:numel(x))'}, G, G);
    Y.trialNumber = [];

end