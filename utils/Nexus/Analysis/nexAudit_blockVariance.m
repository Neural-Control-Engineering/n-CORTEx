function nexAudit_blockVariance(auditDir, comboDir, k, HR, blockColRanges, ctgLabel)
% nexAudit_blockVariance  Write the per-fold, per-region PCA
% explained-variance audit record — how much of each region's raw
% variance the chosen reducerDim component count actually captures.
% HR{b}.explained_variance_ratio is a plain double array captured by
% nexHR_fit itself, right after fitting — not read here from the live
% reducer object, since a fitted sklearn estimator's dynamically-set
% attributes are not reliably re-readable through the MATLAB/Python
% OutOfProcess proxy from a separate, later py.* call chain (confirmed
% empirically: reducer.explained_variance_ratio_ read from here came back
% "Unrecognized property" even though nexHR_transform's own .transform()
% call on that same reducer had already succeeded moments earlier in the
% same fold — proof it really was fitted). blockColRanges(b).label gives
% that block's region name, aligned by block index b.
    nBlk = numel(HR);
    blkLabel = strings(nBlk, 1); blkNComp = zeros(nBlk, 1); blkVarCapt = zeros(nBlk, 1);
    blkRequested = nan(nBlk, 1);
    for b = 1:nBlk
        % n_components (the PRE-fit requested count, i.e. nComp_actual as
        % passed into model_pca — see nexHR_fit) reported alongside the
        % fitted count so a genuinely-empty PCA (0 requested — reducerDim
        % misconfigured, or 0 train rows for this block) is distinguishable
        % from anything else.
        try
            blkRequested(b) = double(HR{b}.reducer.n_components);
        catch
        end
        evr = HR{b}.explained_variance_ratio;
        blkLabel(b)   = string(blockColRanges(b).label);
        blkNComp(b)   = numel(evr);
        blkVarCapt(b) = sum(evr);
    end
    blkTbl = table(blkLabel, blkRequested, blkNComp, blkVarCapt, ...
        'VariableNames', {'region', 'n_components_requested', 'n_components_fitted', 'variance_captured'});
    nexAudit_writeText(auditDir, fullfile(comboDir, sprintf('fold_%d', k), 'block_variance.txt'), evalc('disp(blkTbl)'));

    fig = figure('Visible', 'off');
    bar(blkVarCapt);
    set(gca, 'XTick', 1:nBlk, 'XTickLabel', blkLabel, 'XTickLabelRotation', 45);
    ylabel('variance captured'); ylim([0 1]);
    title(sprintf('%s fold %d — per-region PCA variance captured', ctgLabel, k), 'Interpreter', 'none');
    nexAudit_savePlot(auditDir, fullfile(comboDir, sprintf('fold_%d', k), 'block_variance_bar.png'), fig);
end
