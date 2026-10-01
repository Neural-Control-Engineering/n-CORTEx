function DM = stat2dm_cebra(mdlObj)
    disp("preparing design matrix...");
    STAT = mdlObj.TRAIN.STAT;
    [Z, G, ~] = nexOp_stackSTAT(STAT);

    % Y construction is scoped to domain.TGT — the multi-select target-
    % column bus (mirrors domain.CTG's own selection mechanics; see
    % mdlObject.initViewBus/applyViewBus). Empty TGT means no label at
    % all: pure unsupervised time-contrastive CEBRA (nexFit_cebra calls
    % model.fit(X) alone). Each selected column is routed by type
    % (nexOp_isContinuousVar — same heuristic nexOp_quantizeY already uses
    % for LDA's supervised path) since CEBRA needs them separately:
    %   - continuous columns are z-scored and concatenated into ONE
    %     multi-dim continuous index (CEBRA supports this natively;
    %     unnormalized concatenation would let whichever column has the
    %     larger numeric range dominate the contrastive distance metric)
    %   - discrete columns are jointly encoded into ONE combined class
    %     code (unique-rows, same convention as fitByCombo's own combo-
    %     key construction) — CEBRA 0.5.0 accepts at most one 1D discrete
    %     index, not one per column
    % A TGT selection mixing continuous and discrete columns produces both
    % Y_cont and Y_disc non-empty — nexFit_cebra errors on that combination
    % rather than silently dropping one, since CEBRA 0.5.0 has no single-
    % session loader that trains on both at once (verified against the
    % installed cebra.integrations.sklearn.cebra._init_loader dispatch
    % table — raises NotImplementedError for is_cont && is_disc regardless
    % of hybrid). Use domain.CTG to combo-split by the discrete column(s)
    % instead, keeping TGT continuous-only within each combo.
    tgtCols   = string(mdlObj.domain.TGT);
    validTGT  = tgtCols(ismember(tgtCols, string(G.Properties.VariableNames)));
    isCont    = false(1, numel(validTGT));
    for i = 1:numel(validTGT)
        isCont(i) = nexOp_isContinuousVar(G.(char(validTGT(i))));
    end
    contNames = validTGT(isCont);
    discNames = validTGT(~isCont);

    Y_cont = zeros(height(G), 0);
    if ~isempty(contNames)
        Xc     = table2array(G(:, cellstr(contNames)));
        Y_cont = (Xc - mean(Xc, 1)) ./ std(Xc, 0, 1);
    end

    Y_disc = [];
    if numel(discNames) == 1
        Y_disc = nexOp_labelEncode(G.(char(discNames)));
    elseif numel(discNames) > 1
        [~, ~, Y_disc] = unique(G(:, cellstr(discNames)), 'rows');
    end

    DM.X      = Z;
    DM.Y_cont = Y_cont;
    DM.Y_disc = Y_disc;
end
