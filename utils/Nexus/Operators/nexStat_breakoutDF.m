function dfSet = nexStat_breakoutDF(DF, SS_ax)
    axSels = strrep(convertCharsToStrings(fieldnames(SS_ax)),"ax_","");    
    axVals = structfun(@(f) {f}, SS_ax, "UniformOutput", true);
    DF = nex_initAxisPointer_v2(DF);
    [df_slice, ax_slice] = nexOp_sliceDF(DF, axSels, axVals); % turn into cell fun    
    if ~isempty(fieldnames(SS_ax))
        % arrange coordinate sub-selection
        coords_keep = sort(cellfun(@(f) DF.ptr.(f).dim, cellstr(axSels), "UniformOutput", true)); % only keep applicable axes as coordinates (the others become part of the sample itself)
        coords = cell(1, max(coords_keep));
        numel_samps = size(df_slice); % pecursor variable for numel_samps    
        % MATLAB edge case where final dimension disappears (from a single selection) after slicing 
        if ((max(coords_keep) > max(size(df_slice))))
            % coords_keep = size(df_slice);    
            coords_keep = 1:ndims(df_slice);    
            % coords = coords(:,coords_keep);
        else
            coords = coords(:,coords_keep); % reassign coordinates to ignore inapplicable coordinate (the one that really isn't part of the sample)
        end    
        sz_samps = numel_samps(coords_keep);
        numel_samps = prod(sz_samps);    
        % edge case (only one ax is selected; ind2sub needs at least 2 element vectors)
        if numdim(sz_samps) == 1
            sz_samps = [sz_samps, 1];
        end
        [coords{:}] = ind2sub(sz_samps, 1:numel_samps);             
        axFields = axSels';
        coordCol = [];
        coordIDs = [];
        coordIDs_varName=[];
        for axID = axFields
            % disp(f)
            axDim = DF.ptr.(axID).dim;
            % replace coords column with actual ax coords
            axCol = coords{1,axDim};
            ax_slice_i = ax_slice.(axID);
            if ~isstring(ax_slice_i)         
                axCol(:) = ax_slice_i(axCol(:));   
            else
                axCol = ax_slice_i(axCol(:));   
            end
            coordCol = [coordCol, axCol'];
            axID_varName = sprintf("ax_%s",axID);
            coordIDs_varName = [coordIDs_varName, axID_varName];
            coordIDs = [coordIDs, axID];
        end
        % dfSet = table(df_samples,'VariableNames','df');
        % extract samples from sliced df (according to axis selections SS_ax)   
        try
            axSet = array2table(coordCol, 'VariableNames', convertStringsToChars(coordIDs_varName));% return coordinates for each slice set
        catch e
            % fprintf("WARNING: COMPILE STAT");
            % disp(getReport(e));
            axSet = array2table(coordCol, 'VariableNames', (coordIDs_varName));% return coordinates for each slice set
        end
        DF_slice.df = df_slice;
        DF_slice.ax = ax_slice;
        DF_slice.ptr = DF.ptr;
        rVars = convertCharsToStrings(axSet.Properties.VariableNames);
        rVars = strrep(rVars,"ax_","");
        % dfSet = rowfun(@(r) nexOp_sliceDF(DF_slice, rVars, r), axSet);
        M = axSet{:,:};        % numeric matrix
        dfSet = arrayfun(@(i) nexOp_sliceDF(DF_slice, rVars, num2cell(M(i,:))), 1:size(M,1), "UniformOutput", false)';
        % dfSet = array2table(dfSet,"VariableNames","df");
    else % just return the sample itself
        dfSet = {df_slice};   
        axSet = {};
    end
    dfSet = array2table(dfSet,"VariableNames","df");
    dimHandles = table(DF.ax, DF.ptr, 'VariableNames',["ax","ptr"]);
    % repeat dimHandles as many rows as there are samples
    dimHandles = repmat(dimHandles,height(dfSet),1);
    dfSet = [dfSet, dimHandles, axSet];
    % dfSet = array2table(df_samples,"VariableNames","df");
end