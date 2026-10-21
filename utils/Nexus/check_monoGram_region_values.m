%% Pull the SAME (stratum, f, mdlStep) slice directly out of chainFit4's
%% raw df/ax -- bypassing nexOp_sliceAndCollapse/nexVis_axisToNumeric
%% entirely -- for a direct, independent region-by-region diff against
%% monoGram's own printed table (see the TEMP DEBUG block in
%% nexVisualization_monoGram.m). Fill in the three values below to match
%% whatever monoGram's own console print just reported ("pinned: f=...",
%% "pinned: mdlStep=...") and whichever stratum/VW row is active.

stratumLabel = "L-hind-paw";   % match monoGram's current VW selection
bandValue    = "gamma";        % match monoGram's printed "pinned: f=..."
mdlStepValue = "m1_fe_h5_responseThreshold_g";   % match "pinned: mdlStep=..."

R   = mdl_lme.RESULTS.chainFit4;
structuralCols = ["df", "ax", "ptr", "T_long"];
keyCols = setdiff(string(R.Properties.VariableNames), structuralCols, 'stable');
row = find(R.(char(keyCols(1))) == stratumLabel, 1);
if isempty(row)
    error('No row matches %s=="%s".', keyCols(1), stratumLabel);
end

DF = R.df{row};
AX = R.ax{row};
gridVars = string(fieldnames(AX));
fprintf('Grid axes (df dimension order): %s\n', strjoin(gridVars, ', '));

fIdx = find(string(AX.f) == bandValue, 1);
stepIdx = find(string(AX.mdlStep) == mdlStepValue, 1);
if isempty(fIdx) || isempty(stepIdx)
    error('Could not resolve f="%s" or mdlStep="%s" in this row''s axes.', bandValue, mdlStepValue);
end

% DF dims are (f, chans, t, mdlStep) per computeSignificance's own
% construction -- slice out this one (f, mdlStep) combo, leaving a plain
% [chans x t] matrix, same shape monoGram renders.
slice = squeeze(DF(fIdx, :, :, stepIdx));

fprintf('\nReference (direct from RESULTS.chainFit4): stratum=%s, f=%s, mdlStep=%s\n', ...
    stratumLabel, bandValue, mdlStepValue);
fprintf('columns (t): %s\n', strjoin(string(AX.t), ', '));
for ri = 1:numel(AX.chans)
    % string(NaN) yields a "missing" string element, not the text "NaN" --
    % strjoin/fprintf can't format that (sparse regions, e.g. DG-sg, are
    % mostly NaN). sprintf per-element sidesteps it.
    rowStrs = arrayfun(@(v) sprintf('%.5g', v), slice(ri, :), 'UniformOutput', false);
    fprintf('  %-12s: %s\n', AX.chans(ri), strjoin(rowStrs, ', '));
end
