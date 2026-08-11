function categories = nexOp_listCategories_var(nexon)
% Return category keys for direct manifest per-trial task-variable columns —
% scalar numeric values such as responseThreshold_g, responseDelay,
% withdrawalScore — prefixed "var--".
%
% These are direct manifest table columns; dtsIO_classifyCategory resolves them
% to type "var". nexOp_listCategories_h5 deliberately excludes manifest columns
% (it returns only HDF5-exclusive dfIDs), so without this enumerator scalar task
% variables never appear as foliation categories in the categorical.

    categories = string.empty(0,1);
    DTS = nexon.console.BASE.DTS;
    if isempty(DTS) || ~istable(DTS)
        return;
    end

    vars = string(DTS.Properties.VariableNames);
    % Structural / routing columns are row addresses, not task categories.
    structural = ["sessionLabel","trialNumber","h5_path","h5_root","signal_types"];
    vars = vars(~ismember(vars, structural));

    keep = false(size(vars));
    for i = 1:numel(vars)
        col = DTS.(char(vars(i)));
        if isnumeric(col) && ~iscell(col)
            keep(i) = true;                       % plain numeric per-trial column
        elseif iscell(col)
            % cell-of-scalar (a per-trial scalar written via writeDataframe)
            % counts; cell-of-array (DF data, e.g. lfp_df) or cell-of-string
            % does not.
            nonEmpty = col(~cellfun('isempty', col));
            if ~isempty(nonEmpty)
                first   = nonEmpty{1};
                keep(i) = isnumeric(first) && isscalar(first);
            end
        end
    end
    vars = vars(keep);
    if isempty(vars), return; end

    categories = arrayfun(@(v) "var--" + v, vars(:), 'UniformOutput', true);
end
