function [STAT_join] = nexOp_joinSamples(STAT_struct)
    % join by trialNumber
    STAT = struct2table(STAT_struct);
    G = STAT.trialNumber;
    % STAT_struct = table2struct(STAT);    
    [join, ax, ptr, labels] = splitapply(@(pair) nexOp_concatenateSamplePairs(pair), STAT_struct, G);
    % combine tables in labels using only shared variable names
    if isempty(labels)
        T_labels = table();
    else
        % find intersection of variable names across all tables
        commonVars = labels{1}.Properties.VariableNames;
        for k = 2:numel(labels)
            commonVars = intersect(commonVars, labels{k}.Properties.VariableNames, 'stable');
            if isempty(commonVars)
                break;
            end
        end
        if isempty(commonVars)
            T_labels = table(); % no shared variables
        else
            % vertically concatenate only the common variables, preserving order
            tbls = cellfun(@(t) t(:, commonVars), labels, 'UniformOutput', false);
            T_labels = vertcat(tbls{:});
        end
    end
    % create table from cell arrays join, ax, ptr and merge with T_labels
    n = numel(join);
    if isempty(n)
        STAT_join = table();
    else
        % ensure column vectors
        df_col  = join(:);
        ax_col  = ax(:);
        ptr_col = ptr(:);
        % build table with specified column names
        STAT_join = table(df_col, ax_col, ptr_col, 'VariableNames', {'df','ax','ptr'});
        % if T_labels is nonempty, horizontally concatenate aligning rows
        if ~isempty(T_labels)
            % if number of rows mismatch, error or adjust: prefer matching lengths
            if height(T_labels) ~= height(STAT_join)
                % try to broadcast single-row T_labels to match, otherwise trim/pad with missing
                if height(T_labels) == 1
                    T_labels = repmat(T_labels, height(STAT_join), 1);
                else
                    minr = min(height(T_labels), height(STAT_join));
                    STAT_join = STAT_join(1:minr, :);
                    T_labels = T_labels(1:minr, :);
                end
            end
            STAT_join = [STAT_join, T_labels];
        end
    end
    STAT_join = {STAT_join}; % pack output into a 'scalar' structure
end