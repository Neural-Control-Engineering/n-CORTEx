function ax_out = nexOp_poolAx(pMap, DF, coReg)
% Pool each pMap axis down to bin labels and propagate to co-registered axes.
%
% coReg: struct mapping dependent axis → primary axis.
%        e.g. coReg.unit = 'chans' means unit is co-registered to chans.
%        When the primary axis is binned, each dependent axis is binned with
%        the same positional grouping (same divsPerBin) but its own values,
%        so unit gets unit-ID range labels rather than inheriting chan labels.
%        For mapID (region) binType, dependents inherit the region labels.
    if nargin < 3
        coReg = struct('unit', 'chans');
    end

    ax_out = DF.ax;
    coRegFields = fieldnames(coReg);

    fields = fieldnames(pMap);
    for i = 1:numel(fields)
        f  = fields{i};
        pm = pMap.(f);
        switch f
            case 'time', axName = 't';
            otherwise,   axName = f;
        end
        if ~isfield(ax_out, axName), continue; end
        axVals = ax_out.(axName)(:);
        try
            % Sign of divsPerBin only matters to nexOp_poolAxes (pool vs.
            % defer to the reducer) — the Pointer UI always shows the
            % grouping that magnitude implies either way. abs() so a
            % negative (reduce-mode) magnitude drives the same
            % getBinEdges dispatch a positive (pool-mode) one would.
            isReduce = pm.divsPerBin < 0;
            isMapID  = string(pm.binType) == string(pm.mapID);
            [binEdges, binIDs, binLabels] = pm.getBinEdges(axVals, abs(pm.divsPerBin));
            if isempty(binLabels), continue; end
            if isReduce
                % getBinEdges returns a COMPRESSED one-label-per-group list
                % for any magnitude other than 0 — correct for pool-mode
                % preview (.df really will shrink to that length on
                % commit), but reduce-mode .df never shrinks, so the
                % Pointer must show one label per raw position instead.
                % Reduce mode always uses the expanded STRING labels here
                % regardless of binType, matching nexOp_poolAxes.m's own
                % reduce-mode branch (SWP needs a shared string group key,
                % not numeric arithmetic, for either binType in that mode).
                primaryOut = nexOp_expandGroupLabels(binEdges, binLabels, numel(axVals));
            elseif isMapID
                primaryOut = binLabels;   % region-name strings
            else
                % axID (e.g. time): numeric bin-start values — MUST match
                % nexObj_poolMap.pool()'s own real-pooling assignment
                % (DF_pooled.ax.(axSel) = binIDs). Using the string range
                % labels here instead (as before) made this preview and
                % STAT.ax disagree in TYPE, not just value — applyPointer
                % then silently skips windowing on this axis entirely.
                primaryOut = binIDs;
            end
            ax_out.(axName) = primaryOut;

            % Find any co-registered axes that map to this primary axis
            dependents = coRegFields(cellfun(@(c) strcmp(coReg.(c), axName), coRegFields));
            for j = 1:numel(dependents)
                depName = dependents{j};
                if ~isfield(ax_out, depName), continue; end
                depVals = ax_out.(depName)(:);
                if isMapID
                    % mapID: inherit region labels (positional lookup into
                    % channel region boundaries doesn't apply to unit IDs)
                    ax_out.(depName) = primaryOut;
                else
                    % axID: same positional bins, own values → own numeric
                    % bin-start representative in pool mode (matches
                    % nexOp_poolAxes.m's dependent-axis handling exactly),
                    % or own expanded STRING range labels in reduce mode.
                    [depEdges, depIDs, depLabels] = nexOp_getBinEdges(depVals, abs(pm.divsPerBin));
                    if isReduce
                        ax_out.(depName) = nexOp_expandGroupLabels(depEdges, depLabels, numel(depVals));
                    else
                        ax_out.(depName) = depIDs;
                    end
                end
            end
        catch e
            fprintf('[nexOp_poolAx] %s: %s\n', axName, e.message);
        end
    end
end
