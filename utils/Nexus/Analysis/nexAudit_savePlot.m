function nexAudit_savePlot(auditDir, relPath, fig)
% nexAudit_savePlot  Save figure `fig` to <auditDir>/<relPath> (PNG) and
% close it. Companion to nexAudit_writeText for nexAnalysis_cvPermute's
% opt-in audit trail — callers build the figure (ideally with
% 'Visible','off', since a full audit run can generate many of these and
% none are meant to be looked at interactively) and hand it here to be
% written to disk and cleaned up, so no figure windows pile up across a
% run with many combos/folds.
%
%   fig = figure('Visible','off'); imagesc(X); ...
%   nexAudit_savePlot(auditDir, 'combo_L-hind-paw/fold_1/block_variance_bar.png', fig)
    fullPath = fullfile(auditDir, relPath);
    d = fileparts(fullPath);
    if ~isempty(d) && ~isfolder(d), mkdir(d); end
    try
        exportgraphics(fig, fullPath);
    catch ME
        warning('[nexAudit_savePlot] failed to save %s: %s', fullPath, ME.message);
    end
    close(fig);
end
