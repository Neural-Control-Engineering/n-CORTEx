classdef nexObj_poolMap < handle
    properties
        Parent
        updateFcn=[];
        axID
        mapID
        divsPerBin=1;
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

        function [binEdges, binIDs, binLabels, c_bins] = getBinEdges(poolMap, axis)
            switch poolMap.binType
                case poolMap.mapID
                    % regions = convertCharsToStrings(poolMap.Map.region)';
                    % edges = ([size(regions,2) - ([1, find(~strcmp(regions(1:end-1), regions(2:end))) + 1]-1),0])';
                    % % impute by divisons per bin
                    % edgeCmp = num2cell([edges(1:end-1), edges(2:end)],2);
                    % edgeSubDivs = cellfun(@(row) flip(round(linspace(row(2), row(1),poolMap.divsPerBin+1)',"TieBreaker","fromzero"),1), edgeCmp, "UniformOutput", false);
                    % binEdges = flip(unique(cat(1,edgeSubDivs{:})),1);
                    % % get binIDs
                    % binIDs = regions(binEdges(binEdges~=0))';                
                    % binEdges = flip(binEdges,1);                    
                    axID = poolMap.Map.axID;
                    switch class(axID)
                        case 'cell'
                            binEdges = cell2mat(poolMap.Map.axID);
                        case 'double'
                            binEdges=axID;
                    end
                    binLabels = convertCharsToStrings(poolMap.Map.mapID);
                    %% apply to axis (basically cut off)
                    % subtract max of ax and find where <=0
                    cutOff_start = find((binEdges-min(axis))>=0);
                    cutOff_end = find((binEdges-max(axis))<=0);
                    range = [cutOff_start(1):cutOff_end(end)];
                    binEdges = binEdges(range);
                    binIDs = binEdges(range)';
                    binLabels=binLabels(range)';
                    % binLabels=binIDs;
                    %% edge start correction
                    binEdges_adj = binEdges - (diff([0;binEdges])-1);
                    binEdges = [binEdges_adj; binEdges(end)]; % cap it
                    c_bins = poolMap.Map.color;
                    c_bins=c_bins(range);
                case poolMap.axID
                    % nSteps = ceil((axis(end) - axis(1)) / poolMap.divsPerBin);                    
                    % binEdges = round(linspace(axis(1), nSteps * poolMap.divsPerBin, nSteps))';                    
                    % binIDs_nums = num2cell([binEdges(1:end-1),binEdges(2:end)],2);                    
                    % binIDs = cellfun(@(idRange) sprintf("%d--%d",idRange(1),idRange(2)),binIDs_nums,"UniformOutput",true);                    
                    [binEdges, binIDs, binLabels] = nexOp_getBinEdges(axis, poolMap.divsPerBin);
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
            bins(end) = bins(end)+1; % test - 'correct' included edge
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
            df_pooled = splitapply(@(x) poolMap.cfg.opCfg.fcn(x, 1, 'omitnan'), df_reshape, bins);
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