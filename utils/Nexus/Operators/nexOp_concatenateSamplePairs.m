function [pair_joint, ax, ptr, label] = nexOp_concatenateSamplePairs(pair)
    % join pair and preserve axis definitions
    % pair_join = pair;
    % loop through fields and accumulate/differentiate axes
    T_pair = struct2table(pair);
    % drop df var
    idx_exclude = find(~ismember(T_pair.Properties.VariableNames,'df'));
    T_vars = T_pair(:,idx_exclude);
    varIDs = T_vars.Properties.VariableNames;
    uniqueVars = varfun(@(col) sort(unique(col)), T_vars, "OutputFormat", "cell");
    % decide number of axes needed
    varSizes = cellfun(@(var) max(size(var)), uniqueVars, "UniformOutput", true);
    idx_axDims = find(varSizes>1); % find where a factor has multiple categories (will use this to concatenate the samples)
    IDs_axDims = convertCharsToStrings(varIDs(idx_axDims));
    % prepare label
    idx_labels = find(varSizes<=1);

    % edge-case (no pairings to be made)    
    if isempty(idx_axDims)
        pair_joint = {pair.df};
        % ax = rmfield(pair,'df'); % each ax has its own value (this is actually just the sample-to-be-paired without the df)                
        % build a simple ptr when there are no multi-valued axes:
        % assign each variable (except 'df') to dimension 1 by default
        ptr = {cell2struct( ...
            cellfun(@(v) struct('dim', 1), varIDs, 'UniformOutput', false), ...
            varIDs, 2)};
        label = {T_vars(1,:)}; % return the table itself (first row only)
        ax = {rmfield(pair,'df')};
        return    
    else
        label = {T_vars(1, idx_labels)}; % sub-intersection of non-multi-varying categories (first row only)
    end

    numEls = varSizes(idx_axDims); % number of elements for each factor
    varIDs_ax = varIDs(idx_axDims);
    varVals_ax = {sort(uniqueVars{idx_axDims})};
    S_ax = cell2struct(varVals_ax, varIDs_ax);
    % locate factor indices for each sample/row    
    M = rowfun(@(row) nexOp_row2struct_findIndex(row,  T_vars.Properties.VariableNames, S_ax), T_vars, "SeparateInputs", false, 'NumOutputs',2, 'OutputFormat','cell');
    % idx_ax = cell2mat(M(:,1));
    idx_ax = (M(:,1));
    axProps = convertCharsToStrings(cellstr(M(:,2)));    
    % index each sample into its place in the tensor
    % preallocate tensor
    dims_sample = size(pair(1).df);    
    propDim = [1:length(idx_axDims)] + length(dims_sample); % dimension associated with that particular 'axis'    
    %% TEMPORARY
    propDim_ext1 = [1:length(dims_sample), propDim]; % extend with original axdims    
    varIDs_strings = convertCharsToStrings(varIDs);
    varIDs_ext1 = [varIDs_strings(contains(varIDs_strings,"ax")), IDs_axDims];
    %% TEMPORARY
    % build ptr from varIDs and corresponding dimension order
    dims_joint = [dims_sample, numEls];
    pair_joint = nan(dims_joint);
    % pointer for dimensional bookkeeping
    ptr = {cell2struct( ...
    arrayfun(@(v) struct('dim', v), propDim_ext1, 'UniformOutput', false), ...
    varIDs_ext1, 2)};
    % axis for dimensional bookkeeping
    ax = {S_ax};
    % assign into tensor
    numSamples=size(pair,1);
    sampleSlice = repmat({':'},numSamples,length(dims_sample));
    idxSlice = [sampleSlice, idx_ax];    
    for i = 1:numSamples
        pair_joint(idxSlice{i,:}) = pair(i).df; % assign current sample's data to the tensor
    end
    pair_joint = {pair_joint};    
end