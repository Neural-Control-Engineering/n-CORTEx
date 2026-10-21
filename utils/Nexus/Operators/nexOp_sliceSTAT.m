function STAT_out = nexOp_sliceSTAT(STAT_in, dim, idx)
% Slice every trial's raw .df along one array dimension, keeping only the
% given index/indices — the "raw" (non-needsHR) SWP narrowing primitive.
% Extracted from nexAnalysis_cvPermute.m's own local sliceSTAT/sliceDim
% (DRY — shared by fitSWPGrid and cvPermute's own multi-axis sweep;
% behavior unchanged, just no longer duplicated).
%
% Deliberately touches ONLY .df, not .ax — callers that need this axis's
% own label(s) must read them from .ax BEFORE calling this (same
% convention the original local copy followed: swpAxes resolves vals/
% labels first, sliceSTAT/sliceSWPCombo only narrows the array afterward).
% Also deliberately not squeezed: collapsing a resulting singleton
% dimension would shift every higher dimension index down by one,
% invalidating any .ptr.(axis).dim computed against the pre-slice array.
%
%   STAT_in  : trial table with .df (cell)
%   dim      : array dimension to slice (double)
%   idx      : index/indices to keep along that dimension
%
%   STAT_out : STAT_in with .df narrowed; every other column unchanged
    STAT_out    = STAT_in;
    STAT_out.df = cellfun(@(df) nexOp_sliceSTAT_sliceDim(df, dim, idx), STAT_in.df, 'UniformOutput', false);
end

function X = nexOp_sliceSTAT_sliceDim(A, dim, idx)
    S      = repmat({':'}, 1, ndims(A));
    S{dim} = idx;
    X      = A(S{:});
end
