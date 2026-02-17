function OUT = nexOp_sliceSTATE(STATE, factorSel, dimSel)
    
    % MARC SORRENTINO - slicing state vector for state space visualization
    % under revision (multiple versions to follow)
     % DATE: 2/15/2026

    % slice by factors (vectorized - visit each ax/ptr and isolate element)
    % STATE_struct = table2struct(STATE);
    % factorSel_struct = table2struct(factorSel);
    % factor accumulators
    factorSelIDs = convertStringsToChars(factorSel.ID);
    OUT = table('Size',[0,length(factorSelIDs)],'VariableNames',factorSelIDs, 'VariableTypes', repmat("double",1,numel(factorSelIDs)));    
    % for i = 1:height(STATE)
    %     row_state = STATE(i,:);
    %     [V, F] = nexOp_sliceFactors(row, factorSel);
    %     % accumulate into OUT
    % 
    % 
    % end

    for i = 1:height(STATE)

        row_state = STATE(i,:);
        [V, F] = nexOp_sliceFactors(row_state, factorSel);
        F_str = convertCharsToStrings(F);
    
        % 1. Initialize a new row filled with NaNs
        newRow = array2table( ...
            nan(1, width(OUT)), ...
            'VariableNames', OUT.Properties.VariableNames ...
        );

        idx_assign = find(strcmp(F_str, newRow.Properties.VariableNames));
        % [tf, idx_assign] = ismermber(F_str, newRow.Properties.VariableNames);

        newRow{:,idx_assign} = V(idx_assign);
    
        % 3. Append to OUT
        OUT = [OUT; newRow];

    end

    % slice by dims

    
end