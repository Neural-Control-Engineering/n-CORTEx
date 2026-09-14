classdef nexObj_poolMap < handle
    properties
        Parent
        updateFcn=[];
        axID
        mapID
        divsPerBin=0;
        reducerDim=1;
        binType
        binTypes
        Map
        source_Map
        bins
        spans
        axSel
        cfg
        colors
    end

    methods 

        function poolMap = nexObj_poolMap(Parent, Map, source, axID, mapID)
            poolMap.Parent = Parent;
            poolMap.Map = Map;
            poolMap.axID = axID;
            poolMap.mapID = mapID;            
            poolMap.binTypes = [axID; mapID];
            poolMap.binType=poolMap.binTypes(1);
            poolMap.source_Map = source;        
            poolMap.cfg.opCfg.fcn=@mean;
        end

        function [binEdges, binIDs, binLabels, c_bins] = getBinEdges(poolMap, axis, divsPerBinOverride)
            % divsPerBinOverride lets a caller ask for a different grouping
            % than poolMap.divsPerBin's own configured value without
            % mutating the (handle-class) poolMap object — used by
            % nexHR_fit's region-mode block-PCA, which wants whole-region
            % edges (Inf-style: one block per region, never subdivided)
            % regardless of what divsPerBin is actually set to for pooling.
            if nargin < 3, divsPerBinOverride = poolMap.divsPerBin; end
            switch poolMap.binType
                case poolMap.mapID
                    axID = poolMap.Map.axID;
                    switch class(axID)
                        case 'cell', mapAxID = double(cell2mat(axID(:)));
                        case 'double', mapAxID = double(axID(:));
                    end
                    mapLabels = convertCharsToStrings(poolMap.Map.mapID(:));

                    % Sort by region start value and trim to axis range
                    [mapAxID, sortIdx] = sort(mapAxID);
                    mapLabels = mapLabels(sortIdx);
                    mapColors = {};
                    if ~isempty(poolMap.Map.color)
                        mapColors = poolMap.Map.color(sortIdx);
                    end
                    axMax = double(max(axis(:)));
                    keep = mapAxID <= axMax;
                    mapAxID   = mapAxID(keep);
                    mapLabels = mapLabels(keep);
                    if ~isempty(mapColors), mapColors = mapColors(keep); end

                    % Assign each element to its region by value.
                    % discretize returns NaN (dropped, never binned to any
                    % region) for any value below the FIRST edge. If the
                    % region table's lowest boundary is above the axis's
                    % actual minimum, any unit/channel below it was silently
                    % excluded from the pooled output entirely — but every
                    % unit that exists on the probe physically has to be in
                    % some region, so extend the first region's coverage
                    % down to the true minimum rather than trimming those
                    % positions off. Only the leading edge is affected; the
                    % table's own defined transitions are untouched.
                    axMin = double(min(axis(:)));
                    regionEdges = [min(mapAxID(1), axMin); mapAxID(2:end); axMax + 1];
                    regionBins  = discretize(double(axis(:)), regionEdges);

                    allEdges  = zeros(0, 1);
                    allLabels = string(zeros(0, 1));
                    allColors = {};
                    for r = 1:numel(mapAxID)
                        rPos = find(regionBins == r);
                        if isempty(rPos), continue; end
                        nR = numel(rPos);
                        if divsPerBinOverride == 0
                            % Per-element relabeling: every element gets its region label
                            allEdges  = [allEdges;  rPos];
                            allLabels = [allLabels; repmat(mapLabels(r), nR, 1)];
                            if ~isempty(mapColors)
                                allColors(end+1:end+nR) = repmat(mapColors(r), 1, nR);
                            end
                        elseif isinf(divsPerBinOverride)
                            allEdges  = [allEdges;  rPos(1)];
                            allLabels = [allLabels; mapLabels(r)];
                            if ~isempty(mapColors), allColors{end+1} = mapColors{r}; end
                        else
                            subStart = (1 : divsPerBinOverride : nR)';
                            for s = 1:numel(subStart)
                                allEdges  = [allEdges;  rPos(subStart(s))];
                                allLabels = [allLabels; compose("%s_%d", mapLabels(r), s)];
                                if ~isempty(mapColors), allColors{end+1} = mapColors{r}; end
                            end
                        end
                    end
                    % allEdges was accumulated in region-processing order
                    % (regions sorted by boundary VALUE), not by POSITION.
                    % A stored value out of expected order for even one
                    % position (e.g. two adjacent channel numbers swapped
                    % in the raw data) can make an earlier-processed
                    % region's positions numerically larger than a later
                    % region's — producing a non-monotonic edge list that
                    % discretize/pool() reject ("Bin edges must be ...
                    % monotonically increasing"). For divsPerBin==0 this
                    % sort is lossless: each position already carries its
                    % own independently-assigned label, so reordering by
                    % position doesn't merge, drop, or reassign anything —
                    % it only fixes discretize's technical monotonicity
                    % requirement.
                    [allEdges, sortOrder] = sort(allEdges);
                    allLabels = allLabels(sortOrder);
                    if ~isempty(allColors), allColors = allColors(sortOrder); end

                    if divsPerBinOverride == 0
                        % Coverage check: divsPerBin==0 must produce exactly
                        % one label per input position — no drops, at either
                        % end or in the middle. If the region table (even
                        % after the lower-bound fix above) still leaves any
                        % position uncovered, this catches it immediately
                        % instead of silently shipping a truncated axis.
                        if numel(allEdges) ~= numel(axis)
                            missing = setdiff((1:numel(axis))', allEdges);
                            error('nexObj_poolMap:getBinEdges:coverageGap', ...
                                ['Region assignment dropped %d of %d positions ' ...
                                 '(missing positions: %s) — every position must ' ...
                                 'get a region.'], numel(missing), numel(axis), ...
                                mat2str(missing'));
                        end
                        % Correspondence check: confirm the sort didn't
                        % disturb which label belongs to which position —
                        % independently re-derive each position's region
                        % from regionBins (computed before any sorting) and
                        % compare against the label sitting there now.
                        expectedIdx = regionBins(allEdges);
                        actualLabel = allLabels;
                        expectedLabel = mapLabels(expectedIdx);
                        if ~isequal(actualLabel(:), expectedLabel(:))
                            bad = find(actualLabel(:) ~= expectedLabel(:), 1);
                            error('nexObj_poolMap:getBinEdges:sortMismatch', ...
                                ['Sort broke position-label correspondence at ' ...
                                 'position %d: got "%s", regionBins says "%s".'], ...
                                allEdges(bad), actualLabel(bad), expectedLabel(bad));
                        end
                    end

                    binEdges  = [allEdges; numel(axis) + 1];
                    binLabels = allLabels;
                    binIDs    = allEdges;
                    c_bins    = allColors;
                case poolMap.axID
                    % nSteps = ceil((axis(end) - axis(1)) / poolMap.divsPerBin);                    
                    % binEdges = round(linspace(axis(1), nSteps * poolMap.divsPerBin, nSteps))';                    
                    % binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);                    
                    % binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);                    
                    [binEdges, binIDs, binLabels] = nexOp_getBinEdges(axis, divsPerBinOverride);
                    c_bins=[];
            end            
        end

        function updateScope(poolMap)
            if ~isempty(poolMap.updateFcn)
                poolMap.updateFcn(poolMap);
            end
        end

        function DF_pooled =  pool(poolMap, DF, dim)
            % use pooling Map to bin along selected DF-axis
            ax = DF.ax.(poolMap.axSel);
            axTicks = 1:length(ax);
            [binEdges, binIDs, binLabels] = poolMap.getBinEdges(ax);
            % bin the data
            try
                bins = discretize(axTicks, binEdges);
            catch
                keyboard
            end
            % NOTE: previously had `bins(end) = bins(end)+1;` here ("test -
            % 'correct' included edge"), written for an older getBinEdges
            % that used linspace-truncated edges and left the last position
            % uncovered. Both current binEdges schemes (mapID and axID) end
            % with [...; N+1], so discretize already assigns every position
            % 1..N to a complete, gap-free bin — the hack is now not just
            % unneeded but harmful: if the last bin has few members, bumping
            % one out can leave it empty, which splitapply then rejects
            % ("every integer between 1 and N must occur at least once").
            %% operate (splitapply within bins)
            % Ensure binIDs is a column vector
            bins = bins(:);            
            % Remove NaNs
            validMask = ~isnan(bins);
            bins = bins(validMask);
            % Prepare data slice based on specified dim
            df = DF.df;
            sz = size(df);
            nd = ndims(df);   
            % reshape df such that dimSel follows 1st 
            permuteOrder = [dim, setdiff(1:nd, dim,"stable")];
            df_permute = permute(df, permuteOrder);
            df_reshape = reshape(df_permute, sz(dim), []); % handlind multi-dimensional data
            try
                df_reshape = df_reshape(validMask,:);
            catch 
                keyboard
            end
            % DF_pooled = splitapply(poolMap.cfg.opCfg.fcn, DF.data, findgroups(binIDs));
            try
                df_pooled = splitapply(@(x) poolMap.cfg.opCfg.fcn(x, 1, 'omitnan'), df_reshape, bins);
            catch
                keyboard
            end
            % Reshape output to match original size (except dim gets replaced by #bins)
            sz(dim) = size(df_pooled, 1);    
            sz = sz(permuteOrder); % align back to dim of interest (before unpacking)        
            % binMeans = ipermute(reshape(binMeans, sz(setdiff(1:nd, dim))), permuteOrder);
            df_reshape = reshape(df_pooled, sz);
            % permute back to original format                        
            dimSort = sort(permuteOrder);
            permute_return = arrayfun(@(e) find(e==permuteOrder), dimSort);
            df_pooled = permute(df_reshape, permute_return);
            % store new axes
            DF_pooled=DF;
            DF_pooled.df=df_pooled;
            DF_pooled.ax.(poolMap.axSel)=binIDs;
            DF_pooled.labels.(poolMap.axSel)=binLabels;
        end

    end
end