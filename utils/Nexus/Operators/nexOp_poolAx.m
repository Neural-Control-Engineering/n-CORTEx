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
            [binEdges, ~, binLabels] = pm.getBinEdges(axVals, abs(pm.divsPerBin));
            if isempty(binLabels), continue; end
            if isReduce
                % getBinEdges returns a COMPRESSED one-label-per-group list
                % for any magnitude other than 0 — correct for pool-mode
                % preview (.df really will shrink to that length on
                % commit), but reduce-mode .df never shrinks, so the
                % Pointer must show one label per raw position instead.
                binLabels = nexOp_expandGroupLabels(binEdges, binLabels, numel(axVals));
            end
            ax_out.(axName) = binLabels;

            % Find any co-registered axes that map to this primary axis
            dependents = coRegFields(cellfun(@(c) strcmp(coReg.(c), axName), coRegFields));
            for j = 1:numel(dependents)
                depName = dependents{j};
                if ~isfield(ax_out, depName), continue; end
                depVals = ax_out.(depName)(:);
                if string(pm.binType) == string(pm.axID)
                    % axID: same positional bins, own values → own range labels
                    [depEdges, ~, depLabels] = nexOp_getBinEdges(depVals, abs(pm.divsPerBin));
                    if isReduce
                        depLabels = nexOp_expandGroupLabels(depEdges, depLabels, numel(depVals));
                    end
                else
                    % mapID: inherit region labels (positional lookup into
                    % channel region boundaries doesn't apply to unit IDs)
                    depLabels = binLabels;
                end
                ax_out.(depName) = depLabels;
            end
        catch e
            fprintf('[nexOp_poolAx] %s: %s\n', axName, e.message);
        end
    end
end
