function nexAudit_swpCellDM(auditDir, cellDir, cellLabel, DM, blockColRanges)
% nexAudit_swpCellDM  Visualize one fitSWPGrid grid cell's final DM —
% exactly what that cell's own cfg.fitCfg.fcn is about to fit/train on,
% after CTG slicing AND SWP narrowing (column-mask for an "ftr"-mode SWP
% axis, row-mask for "pool"/other, or a fresh getDesignMatrix() on
% re-sliced STAT for a non-needsHR "raw" SWP axis). Same imagesc +
% line-plot-companion style as nexAudit_fitSWPGridTrace/
% nexAnalysis_cvPermute's own nexAudit_singleTrialTrace, scoped to one
% already-finished DM instead of a multi-stage trial trace.
%
%   cellDir        : directory for this cell's files, relative to auditDir
%   cellLabel       : display label identifying this combo+SWP cell
%   DM              : (nRows, nFeatures) — this cell's own design matrix
%   blockColRanges  : optional (struct array or []) — this cell's own
%                     FTR_blockColRanges, for region-boundary lines
%                     (ftr/pool mode only; [] for raw mode, which has none)
    if nargin < 5, blockColRanges = []; end

    fig = figure('Visible', 'off');
    imagesc(DM); colorbar; hold on;
    for b = 1:numel(blockColRanges)
        xline(min(blockColRanges(b).cols) - 0.5, 'w-');
    end
    hold off;
    xlabel('feature index'); ylabel('row index');
    title(sprintf('%s — cell DM %s', cellLabel, mat2str(size(DM))), 'Interpreter', 'none');
    nexAudit_savePlot(auditDir, fullfile(cellDir, 'cell_dm.png'), fig);

    nFeat = size(DM, 2);
    if nFeat <= 20 && size(DM, 1) > 1
        legendLabels = compose("f%d", 1:nFeat);
        fig = figure('Visible', 'off');
        plot(DM); xlabel('row index'); ylabel('value');
        title(sprintf('%s — cell DM (lines)', cellLabel), 'Interpreter', 'none');
        legend(legendLabels, 'Location', 'eastoutside');
        nexAudit_savePlot(auditDir, fullfile(cellDir, 'cell_dm_lines.png'), fig);
    end

    nexAudit_writeText(auditDir, fullfile(cellDir, 'cell_summary.txt'), ...
        sprintf('%s\nDM shape: %s\n', cellLabel, mat2str(size(DM))));
end
