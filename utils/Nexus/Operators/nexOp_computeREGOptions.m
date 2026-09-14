function regOpts = nexOp_computeREGOptions(ftrAxes, ax)
% Derive valid REG axis options from the currently selected FTR axes.
%
% REG candidates = "None" ∪ co-indexed partners of any FTR axis ∪ FTR axes
% themselves when they plausibly carry cross-session identity. Time ('t') is
% never a valid REG axis.
%
% NOTE: The current co-index registry seeds only from {chans, unit} — the
% minimum pair for channel-position and unit-ID cross-session alignment.
% Future work may extend this to richer co-registration structures (probe
% geometry, multi-area hierarchies, electrode array layouts, matched stimulus
% IDs, etc.). When that happens, nexOp_coIndexPairs is the only other site
% to update; the REG bus and nexOp_alignCoAxes require no changes.
    regOpts = "None";
    if isempty(ftrAxes) || isempty(ax), return; end
    pairs   = nexOp_coIndexPairs(ax);
    axNames = string(fieldnames(ax))';
    for i = 1:numel(ftrAxes)
        f = char(ftrAxes(i));
        if strcmp(f, 't'), continue; end
        % co-indexed partners (e.g. 'unit' ↔ 'chans')
        for p = 1:numel(pairs)
            if ismember(f, pairs{p})
                cands = string(pairs{p});
                cands = cands(ismember(cands, axNames));
                regOpts = union(regOpts, cands, 'stable');
            end
        end
        % FTR axis itself (e.g. selecting 'unit' as FTR → 'unit' is also REG candidate)
        if ismember(f, axNames)
            regOpts = union(regOpts, string(f), 'stable');
        end
    end
end
