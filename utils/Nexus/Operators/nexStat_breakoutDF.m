function dfSet = nexStat_breakoutDF(DF, SS_ax)
    axSels = strrep(convertCharsToStrings(fieldnames(SS_ax)),"ax_","");    
    axVals = structfun(@(f) {f}, SS_ax, "UniformOutput", true);
    DF = nex_initAxisPointer_v2(DF);
    [df_slice, ax_slice] = nexOp_sliceDF(DF, axSels, axVals); % turn into cell fun    
    % coords = cell(1, ndims(DF.df));
    % coords = cell(1, numel(fieldnames(SS_ax)));
    % [coords{:}] = ind2sub(size(df_slice),1:numel(df_slice));
    % [coords{:}] = ind2sub(size(df_slice),1:numel(df_slice));
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
    % coords = cell(1, max(coords_keep));
    sz_samps = numel_samps(coords_keep);
    numel_samps = prod(sz_samps);
    % [coords{:}] = ind2sub(size(df_slice),1:numel(df_slice));    
    [coords{:}] = ind2sub(sz_samps, 1:numel_samps);    
    % coords = coords(:,coords_keep);
    % df_samples = df_slice(:);
    % axFields = convertCharsToStrings(fieldnames(DF.ptr))';
    % axFields = convertCharsToStrings(fieldnames())';
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
        axCol(:) = ax_slice_i(axCol(:));   
        coordCol = [coordCol, axCol'];
        axID_varName = sprintf("ax_%s",axID);
        coordIDs_varName = [coordIDs_varName, axID_varName];
        coordIDs = [coordIDs, axID];
    end
    % dfSet = table(df_samples,'VariableNames','df');
    % extract samples from sliced df (according to axis selections SS_ax)   
    axSet = array2table(coordCol, 'VariableNames', convertStringsToChars(coordIDs_varName));% return coordinates for each slice set
    DF_slice.df = df_slice;
    DF_slice.ax = ax_slice;
    DF_slice.ptr = DF.ptr;
    rVars = convertCharsToStrings(axSet.Properties.VariableNames);
    rVars = strrep(rVars,"ax_","");
    % dfSet = rowfun(@(r) nexOp_sliceDF(DF_slice, rVars, r), axSet);
    M = axSet{:,:};        % numeric matrix
    dfSet = arrayfun(@(i) nexOp_sliceDF(DF_slice, rVars, num2cell(M(i,:))), 1:size(M,1), "UniformOutput", false)';
    dfSet = array2table(dfSet,"VariableNames","df");
    dfSet = [dfSet, axSet];
    % dfSet = array2table(df_samples,"VariableNames","df");
end