function DF_pooled = nexOp_poolAxes(pMap, DF, ptr)
    fields_pMap = fieldnames(pMap);
    DF_pooled = DF;
    if ~isempty(DF_pooled.df)
        for i = 1:length(fields_pMap)
            field_pMap = fields_pMap{i};
            pm = pMap.(field_pMap);
            % divsPerBin's SIGN selects who reduces this axis's data:
            %   >= 0 → pool() collapses .df here (mean/whatever), as always.
            %   <  0 → block-PCA, handled downstream by
            %          mdlObject.initReducer/nexHR_fit, which needs the raw,
            %          unreduced .df — pm.pool() must not run for this axis.
            % Either way, .ax/.labels get relabeled using abs(divsPerBin)'s
            % magnitude through the same getBinEdges dispatch pooling uses
            % (0/N/Inf, mapID- or axID-aware) — so STAT.ax (which SWP's
            % unique-value grouping reads) and the Pointer UI always show
            % the true grouping, whether this axis is pooled or reduced.
            isReduce = pm.divsPerBin < 0;
            %
            % divsPerBin == 0 means two different things depending on
            % binType, so this skip has to be conditional rather than a flat
            % threshold:
            %   - mapID (e.g. chans → region): "relabel every element to its
            %     region, don't reduce count" — must proceed to pm.pool().
            %   - axID (e.g. time, continuous): explicit "no-op, don't touch
            %     this axis at all" — must skip. getBinEdges correctly
            %     returns empty for this case; discretize can't accept empty
            %     edges, so this axis must never reach pm.pool() at all.
            if pm.divsPerBin == 0 && string(pm.binType) == string(pm.axID)
                continue;
            end
            switch field_pMap
                case "time"
                    ax = "t";
                otherwise
                    ax = field_pMap;
            end
            % ptr is an axis-pointer object, not a plain struct — isfield()
            % always returns false for non-struct types even when the
            % property genuinely exists (fieldnames()/dynamic dot-access
            % work fine on objects; isfield() is struct-only). Every isfield
            % check against ptr itself must use fieldnames-membership
            % instead, or it silently fails as if the field were absent.
            if ismember(char(ax), fieldnames(ptr))
                dim = ptr.(ax).dim;
            else
                continue
            end
            if isempty(dim)
                % pMap configured directly on a co-indexed label (e.g.
                % pMap.chans, when chans doesn't own a real array dimension —
                % unit does, until a pMap.unit exists in its own right).
                % Resolve the owning sibling's dimension so pooling still
                % runs: bin edges come from chans' own values (pm.axSel),
                % but the actual data reduction happens along whichever
                % co-indexed sibling owns the dimension, since co-indexed
                % axes share length and positionality.
                coIdx = nexOp_coIndexPairs(DF_pooled.ax);
                ptrFields = fieldnames(ptr);
                for p = 1:numel(coIdx)
                    pair = coIdx{p};
                    if ~ismember(char(ax), pair), continue; end
                    for mIdx = 1:numel(pair)
                        cand = char(pair{mIdx});
                        if strcmp(cand, char(ax)) || ~ismember(cand, ptrFields), continue; end
                        if ~isempty(ptr.(cand).dim)
                            dim = ptr.(cand).dim;
                            break;
                        end
                    end
                    if ~isempty(dim), break; end
                end
            end
            if ~isempty(dim)
                try
                    % Pre-compute bin membership for co-registration before
                    % pm.pool runs — mirrors the discretize logic inside pool().
                    % Resolve co-indexed pairs the same way nexOp_coAlign does
                    % (DF.coIdx if present, else derived from .ax fieldnames)
                    % rather than requiring .coIdx to already exist — raw DFs
                    % read from disk never get .coIdx populated (it's only
                    % written by dtsIO_composeDF at export/write time, not
                    % reconstructed on read), so gating on isfield(...,'coIdx')
                    % silently skipped this block for every real analysis run.
                    coGroups  = [];
                    preCoAxes = struct();
                    % Scoped to whether THIS axis specifically is part of a
                    % co-indexed pair — not whether any pair exists anywhere
                    % in the DF. The unscoped version incorrectly routed every
                    % axis (including "t") through co-registration precompute
                    % logic meant only for the paired axes (e.g. chans/unit),
                    % crashing pm.getBinEdges/compose on the time axis.
                    coIdxPairs = nexOp_coIndexPairs(DF_pooled.ax);
                    hasCoIdx   = (isfield(DF_pooled, 'coIdx') && ~isempty(DF_pooled.coIdx)) || ...
                                 any(cellfun(@(pair) ismember(char(ax), pair), coIdxPairs));
                    if hasCoIdx
                        ax_vals  = DF_pooled.ax.(char(ax));
                        nPos     = numel(ax_vals);
                        [binEdges, ~, ~] = pm.getBinEdges(ax_vals, abs(pm.divsPerBin));
                        mBins    = discretize(1:nPos, binEdges);
                        % No end-of-vector +1 correction: binEdges already
                        % ends with [...; N+1], so discretize covers every
                        % position with no gap needing a manual bump (see the
                        % matching fix in nexObj_poolMap.pool()).
                        valid    = ~isnan(mBins);
                        nBins    = max(mBins(valid));
                        coGroups = arrayfun(@(b) find(valid(:)' & mBins == b), ...
                                           1:nBins, 'UniformOutput', false);
                        % Save pre-pool values for all co-registered partners
                        preMasks = nexOp_coAlign(DF_pooled, char(ax), coGroups);
                        coF_all  = fieldnames(preMasks);
                        for cf = coF_all'
                            coF = cf{1};
                            if ~strcmp(coF, char(ax)) && isfield(DF_pooled.ax, coF)
                                preCoAxes.(coF) = DF_pooled.ax.(coF);
                            end
                        end
                    end

                    if isReduce
                        % Reduce mode: relabel only — .df stays raw so
                        % mdlObject.initReducer/nexHR_fit can block-PCA it
                        % later; pm.pool() would collapse it, so it must not
                        % run here. getBinEdges returns a COMPRESSED
                        % one-label-per-group list for any magnitude other
                        % than 0 (correct for pooling, where .df actually
                        % shrinks to match) — but .df here never shrinks, so
                        % .ax must stay at the full raw length too. Expand
                        % back to one label per position.
                        ax_vals = DF_pooled.ax.(char(ax));
                        nPos    = numel(ax_vals);
                        [binEdges, ~, binLabels] = pm.getBinEdges(ax_vals, abs(pm.divsPerBin));
                        binLabels = nexOp_expandGroupLabels(binEdges, binLabels, nPos);
                        DF_pooled.ax.(char(ax))     = binLabels;
                        DF_pooled.labels.(char(ax)) = binLabels;
                    else
                        DF_pooled = pm.pool(DF_pooled, dim);

                        isMapID   = string(pm.binType) == string(pm.mapID);
                        hasLabels = isfield(DF_pooled, 'labels') && isfield(DF_pooled.labels, char(ax));

                        % pool() writes numeric binIDs into .ax and stashes
                        % the human-readable labels separately in .labels.
                        % For mapID (region) pooling, binIDs are just raw
                        % position indices — meaningless in .ax — so mirror
                        % the region-name labels in instead, matching what
                        % the Pointer UI (Tier-1's nexOp_poolAx) shows. For
                        % axID pooling, binIDs are genuinely meaningful
                        % numeric bin-start values (and, for an evenly-
                        % spaced axis like time, still evenly spaced after
                        % pooling) — overwriting them with "v1--v2" range
                        % strings breaks any numeric consumer (e.g.
                        % nexVisualization_stateSpace's animate-step
                        % tolerance, which subtracts adjacent axis values),
                        % so leave pool()'s own numeric assignment alone.
                        if isMapID && hasLabels
                            DF_pooled.ax.(char(ax)) = DF_pooled.labels.(char(ax));
                        end
                    end

                    % Relabel co-registered dependents to match Tier-1's
                    % nexOp_poolAx exactly: mapID → same label as the primary
                    % (e.g. 'chans' inherits 'unit's region string); axID →
                    % the dependent's own positionally-recomputed range label
                    % (same bin count as the primary, since co-indexed = same
                    % length, but described in the dependent's own values).
                    % This is what Pointer-bus matching in applyPointer needs
                    % (labels matching what the UI displays).
                    if ~isempty(coGroups)
                        coF_all = fieldnames(nexOp_coAlign(DF_pooled, char(ax), coGroups));
                        isAxID  = string(pm.binType) == string(pm.axID);
                        for ci = 1:numel(coF_all)
                            coF = coF_all{ci};
                            if strcmp(coF, char(ax)) || ~isfield(preCoAxes, coF), continue; end
                            if isAxID
                                preAx = preCoAxes.(coF);
                                [depEdges, depIDs, depLabels] = nexOp_getBinEdges(preAx, abs(pm.divsPerBin));
                                if isReduce
                                    % Same compressed-vs-raw-length issue as
                                    % the primary axis above: .df (and thus
                                    % this dependent's real dimension) never
                                    % shrinks in reduce mode. Region-mode
                                    % grouping stays string-based here (SWP
                                    % needs a shared group key, not numeric
                                    % arithmetic) — same as the primary axis.
                                    depLabels = nexOp_expandGroupLabels(depEdges, depLabels, numel(preAx));
                                    DF_pooled.ax.(coF) = depLabels;
                                else
                                    % Pool mode: numeric bin-start
                                    % representative, matching the primary
                                    % axis's own pool()-assigned .ax value
                                    % (see the primary-axis comment above —
                                    % not the "v1--v2" display string).
                                    DF_pooled.ax.(coF) = depIDs;
                                end
                            else
                                DF_pooled.ax.(coF) = DF_pooled.ax.(char(ax));
                            end
                        end
                    end
                catch e
                    fprintf('[nexOp_poolAxes] axis "%s" pooling failed: %s\n', char(ax), e.message);
                end
            end
        end
    end
end
