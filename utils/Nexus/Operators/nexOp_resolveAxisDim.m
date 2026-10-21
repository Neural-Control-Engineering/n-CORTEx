function dim = nexOp_resolveAxisDim(ax, ptr, axisName)
% Resolve axisName's own array dimension from ptr, falling back to a
% co-indexed sibling's dimension when axisName is itself a co-indexed
% label with no dimension of its own (e.g. 'chans' riding on 'unit').
% Extracted from nexAnalysis_cvPermute.m's own local resolveAxisDim (DRY
% — shared by fitSWPGrid's single-axis SWP resolution and cvPermute's own
% multi-axis sweep; behavior unchanged, just no longer duplicated).
%
%   ax       : STAT.ax(i) — one trial's axis struct
%   ptr      : STAT.ptr(i) — same trial's axis pointer struct
%   axisName : axis name (char/string)
%
%   dim      : array dimension (double), or [] if unresolvable
    axisName  = char(axisName);
    dim       = [];
    ptrFields = fieldnames(ptr);
    if ismember(axisName, ptrFields) && ~isempty(ptr.(axisName).dim)
        dim = ptr.(axisName).dim;
        return;
    end
    coIdx = nexOp_coIndexPairs(ax);
    for p = 1:numel(coIdx)
        pair = coIdx{p};
        if ~ismember(axisName, pair), continue; end
        for m = 1:numel(pair)
            cand = char(pair{m});
            if strcmp(cand, axisName), continue; end
            if ismember(cand, ptrFields) && ~isempty(ptr.(cand).dim)
                dim = ptr.(cand).dim;
                return;
            end
        end
    end
end
