function L = nexOp_labelEncode(labelCol)
    % L=[];
    labels_unique = unique(labelCol);
    L = arrayfun(@(elem) find(ismember(labels_unique, elem)), labelCol);
    % key.code=[1:length(labels_unique)];
    % key.label=labels_unique;
end