function masks = nexOp_coAlign(DForAx, primaryAxis, primaryMask)
% Propagate a positional mask from primaryAxis to every co-registered axis.
%
%   masks.(primaryAxis) = primaryMask
%   masks.(pairedAxis)  = primaryMask   (same structure — co-indexed)
%
%   DForAx      : DF struct (reads .coIdx), full DF struct (reads .ax then
%                 falls back to nexOp_coIndexPairs), or plain ax struct
%   primaryAxis : char/string axis name
%   primaryMask : determines propagation mode —
%
%     FILTER MODE  (nDivsPerBin = Inf, applyPointer callers):
%       flat numeric/logical index vector → same flat vector on all co-axes
%       ax.unit stays a flat vector; 1:1 co-registration preserved
%
%     POOL MODE  (finite nDivsPerBin, pm.pool callers):
%       cell array of index groups, e.g. {[3 4], [5 6]} → same cell on all
%       co-axes; ax.unit becomes {[4 5], [6 7]} (membership sets per bin)
%       Caller is responsible for writing the cell into DF.ax.(pairedAxis)
%
%   nexOp_coAlign is mask-type agnostic: it propagates whatever primaryMask
%   is.  The caller chooses the mode by the type it passes in.

    primaryAxis = char(primaryAxis);
    masks.(primaryAxis) = primaryMask;

    % Resolve coIdx — prefer DF.coIdx, fall back to deriving from ax struct
    if isfield(DForAx, 'coIdx')
        coIdx = DForAx.coIdx;
    elseif isfield(DForAx, 'ax')
        coIdx = nexOp_coIndexPairs(DForAx.ax);
    else
        coIdx = nexOp_coIndexPairs(DForAx);   % plain ax struct
    end

    if isempty(coIdx), return; end

    for p = 1:numel(coIdx)
        pair = coIdx{p};
        if ~ismember(primaryAxis, pair), continue; end
        for m = 1:numel(pair)
            other = char(pair{m});
            if strcmp(other, primaryAxis), continue; end
            masks.(other) = primaryMask;
        end
    end
end
