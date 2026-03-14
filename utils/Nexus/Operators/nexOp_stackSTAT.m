function [Z_stack, G_stack, S_stack] = nexOp_stackSTAT(STAT)
    % return Z domain, G grouping, and S size (given sem/covariance/error)
    Z_stack = cat(1, STAT.df{:});
    try
        S_stack = cat(1, STAT.cov{:});
    catch
        S_stack = [];
    end
    % label each coordinate along the primary axis with the corresponding
    % groups
    % TRY: nexStat_breakoutDF
    statProps = STAT.Properties.VariableNames;
    statProps = statProps(~ismember(statProps,["df","ax","ptr", "cov","sem","labels"])); % leave out key fields
    STAT_G = STAT(:,statProps);
    repHeights = cellfun(@(df) size(df,1), STAT.df, "UniformOutput", false);        
    G_cell = table2cell(STAT_G);
    repHeights = repmat(repHeights,1,size(G_cell,2));
    G_stack = cellfun(@(g, repHeight) nexOp_repElem(g, repHeight), G_cell, repHeights, "UniformOutput", false);
    % G_stack = varfun(@(var) cellfun(@(elem, repHeight) nexOp_repElem(elem, repHeight), var, repHeights, "UniformOutput",false), STAT_G);
    %% add sample number col
    SN_stack = cellfun(@(df) [1:size(df,1)]', STAT.df, "UniformOutput", false);
    G_stack = [G_stack, SN_stack];    
    varNames = [STAT_G.Properties.VariableNames, "sampleNumber"];
    % G_stack = varfun(@(var) cat(1, var{:}), G_stack);    
    % G_cat = cellfun(@(g) cat(1, g{:}), G_stack, "UniformOutput", false);
    % G_cat = cat(1, G_stack{:,:});
    G_cat = colfun(@(col) cat(1,col{:}), G_stack)';
    G_stack = table(G_cat{:}, 'VariableNames', varNames);
    % G_T.Properties.VariableNames=varNames;
    
end