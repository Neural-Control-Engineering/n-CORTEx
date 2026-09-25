function DM = stat2dm_supervised(mdlObj)
    disp("preparing design matrix...");
    % STAT = mdlObj.Origin.STAT;  
    STAT = mdlObj.TRAIN.STAT;
    % STAT.df = nexOp_trimDfCol(STAT.df);
    % dnSel=mdlObj.domain.DN(1);
    % ptr = STAT.ptr(1);
    % % place primary dim first
    % STAT.df = cellfun(@(df) nexOp_permute2First(df, dnSel, ptr), STAT.df, "UniformOutput", false);
    % isolate target-variable
    tVar = char(mdlObj.dfID_target);

    % Quantize a continuous Y into nBins quantile groups, mirroring the
    % reportAverage convention (nexFigure_addAvgControls.m): nBins default
    % Inf disables binning (today's unquantized passthrough behavior).
    % edges (empty when not quantized) is stashed in DM.K.(tVar) below so
    % scoreFold can discretize TEST Y with the exact same bin boundaries —
    % quantizing train and never touching test silently scores as ~random
    % (predictions land in bin-ID space, compared against raw continuous
    % test values that essentially never match).
    edges = [];
    if ~strcmp(tVar,"all")
        nBins = Inf;
        try
            nBins = mdlObj.collector.Target.nBins;
        catch
        end
        [STAT.(tVar), edges] = nexOp_quantizeY(STAT.(tVar), nBins);
    end

    STAT_cell = table2cell(STAT);
    STAT_cell = cellfun(@(c) {c}, STAT_cell, "UniformOutput", true);
    T = cell2table(STAT_cell, 'VariableNames', STAT.Properties.VariableNames);
    [Z, G, S] = nexOp_stackSTAT(STAT);
    if ~strcmp(tVar,"all")
        G = G.(tVar);
        G = array2table(G,"VariableNames",{tVar});
        labels_unique = unique(STAT.(tVar));
        key.code=[1:length(labels_unique)];
        key.label=labels_unique;
        key.edges=edges;
    end
    % label encoding
    L = varfun(@(var) nexOp_labelEncode(var), G);

    % result
    DM.X=Z;
    DM.Y=table2array(L);
    DM.K.(tVar)=key; % future: expand to all
end