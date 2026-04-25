function DM = stat2dm_supervised(mdlObj)
    disp("preparing design matrix...");
    % STAT = mdlObj.Origin.STAT;  
    STAT = mdlObj.TRAIN.STAT;
    % STAT.df = nexOp_trimDfCol(STAT.df);
    % d1Sel=mdlObj.domain.D1(1);
    % ptr = STAT.ptr(1);
    % % place primary dim first
    % STAT.df = cellfun(@(df) nexOp_permute2First(df, d1Sel, ptr), STAT.df, "UniformOutput", false);        
    STAT_cell = table2cell(STAT);
    STAT_cell = cellfun(@(c) {c}, STAT_cell, "UniformOutput", true);
    T = cell2table(STAT_cell, 'VariableNames', STAT.Properties.VariableNames);
    [Z, G, S] = nexOp_stackSTAT(STAT);
    % isolate target-variable
    tVar = char(mdlObj.dfID_target);
    if ~strcmp(tVar,"all")
        G = G.(tVar);
        G = array2table(G,"VariableNames",{tVar});
        labels_unique = unique(STAT.(tVar));
        key.code=[1:length(labels_unique)];
        key.label=labels_unique;
    end
    % label encoding
    L = varfun(@(var) nexOp_labelEncode(var), G);

    % result
    DM.X=Z;
    DM.Y=table2array(L);
    DM.K.(tVar)=key; % future: expand to all
end