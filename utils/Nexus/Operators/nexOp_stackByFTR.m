function [X, G] = nexOp_stackByFTR(STAT, ftrAxis)
% Stack STAT's raw per-trial DFs into (totalSamples x nFeatures), keeping
% ONLY ftrAxis as feature columns — every OTHER axis (DN, a pool-mode axis
% like t, or anything else) is folded into the sample/row dimension. This
% is the "DN vs FTR vs everything else" convention (see WIP.md #1),
% specialized to a caller-given single feature axis rather than
% domain.DN — what nexHR_fit's own (N_ctx, outermost) input shape needs
% when a pool-mode axis must stay raw (folded into N_ctx as extra samples,
% not pre-collapsed) so reduction sees full temporal resolution.
%
% Axis→dimension resolution is always by NAME via each row's own .ptr
% (never a positional/"dim2 is always F" assumption) — raw per-trial DF
% dimension order is not guaranteed uniform enough to assume otherwise.
%
%   STAT    : trial table with .df (cell), .ax (struct array), .ptr
%   ftrAxis : single axis name (char/string) to KEEP as feature columns —
%             everything else folds into rows. Multi-axis FTR (nexHR_fit's
%             hierarchical layout) is not supported by this function; every
%             current caller only ever has one FTR axis.
%
%   X : (totalSamples, nFeatures) — feature axis's raw width
%   G : table, one row per sample in X — one column per folded-in axis
%       (that axis's own value at that sample), every STAT-level column
%       (session labels etc.), plus "trialIdx" (which STAT row/trial this
%       sample came from — named to avoid colliding with STAT's own
%       pre-existing "trialNumber" column, written by nexOp_compileSTAT
%       and carrying a different meaning: trial number within a
%       session/subject/phase grouping) and "sampleNumber"

    ftrAxis = char(ftrAxis);
    nTrials = height(STAT);

    X_cell = cell(nTrials, 1);
    G_cell = cell(nTrials, 1);

    statProps = STAT.Properties.VariableNames;
    statProps = statProps(~ismember(statProps, ["df","ax","ptr","cov","sem","labels","fitSentinel"]));
    STAT_G    = STAT(:, statProps);

    for i = 1:nTrials
        df_i  = STAT.df{i};
        ax_i  = STAT.ax(i);
        ptr_i = STAT.ptr(i);

        if ~isfield(ax_i, ftrAxis) || ~isprop(ptr_i, ftrAxis) || isempty(ptr_i.(ftrAxis).dim)
            error('nexOp_stackByFTR:noFTRDim', ...
                'Trial %d: FTR axis "%s" has no resolvable dimension.', i, ftrAxis);
        end
        ftrDim    = ptr_i.(ftrAxis).dim;
        otherDims = setdiff(1:ndims(df_i), ftrDim, 'stable');

        % Move FTR dim to the end; fold everything else into one leading dim.
        df_perm = permute(df_i, [otherDims, ftrDim]);
        szPerm  = size(df_perm);
        nOther  = prod(szPerm(1:numel(otherDims)));
        nFeat   = szPerm(end);
        X_cell{i} = reshape(df_perm, [nOther, nFeat]);

        % Companion rows: one per folded sample, one column per folded-in
        % axis (its own value at that position), same column-major
        % Nbefore/Nafter expansion nexOp_stackSTAT's expandAxCol already
        % uses, plus this trial's STAT-level columns broadcast to every row.
        otherAxNames = fieldnames(ax_i);
        otherAxNames = otherAxNames(~strcmp(otherAxNames, ftrAxis));
        axCols   = cell(1, numel(otherAxNames));
        colNames = strings(1, numel(otherAxNames));
        for a = 1:numel(otherAxNames)
            f = otherAxNames{a};
            if ~isprop(ptr_i, f) || isempty(ptr_i.(f).dim), continue; end
            fDim = find(otherDims == ptr_i.(f).dim, 1);
            if isempty(fDim), continue; end
            axVals  = ax_i.(f)(:);
            nBefore = prod(szPerm(1:fDim-1));
            nAfter  = prod(szPerm(fDim+1:numel(otherDims)));
            axCols{a}  = repmat(repelem(axVals, max(1,nBefore)), max(1,nAfter), 1);
            colNames(a) = string(f);
        end
        keep     = ~cellfun(@isempty, axCols);
        axCols   = axCols(keep);
        colNames = colNames(keep);

        trialCell = table2cell(STAT_G(i, :));
        trialRep  = cellfun(@(c) repmat({c}, nOther, 1), trialCell, 'UniformOutput', false);
        trialRep  = cellfun(@(c) vertcat(c{:}), trialRep, 'UniformOutput', false);

        rowNames = [colNames, "trialIdx", "sampleNumber", string(statProps)];
        rowVals  = [axCols, {repmat(i, nOther, 1)}, {(1:nOther)'}, trialRep];
        G_cell{i} = table(rowVals{:}, 'VariableNames', cellstr(rowNames));
    end

    X = cat(1, X_cell{:});
    G = cat(1, G_cell{:});
end
