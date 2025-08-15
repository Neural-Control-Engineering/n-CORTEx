function nex_storeAverage(nexObj, DF)
    % Extract current phase name
    phase = DF.avgCfg.phase;  % Assuming this is a string or char
    phase = strrep(phase,"-","_");
    DF.avgCfg = rmfield(DF.avgCfg,"phase");
    DF.avgCfg = rmfield(DF.avgCfg,"date");
    % Build new row
    AVG = struct();
    AVG.(phase) = DF;     % DF.AVG must exist and be a struct or numeric/etc
    avgCfg = DF.avgCfg;

    % Create a table row
    newRow = table({AVG}, avgCfg,'VariableNames',{'AVG','avgCfg'});
    % Append or initialize Obj.UserData.T_avg
    if ~isfield(nexObj.UserData, 'T_avg') || isempty(nexObj.UserData.T_avg)
        nexObj.UserData.T_avg = newRow;
    else
        % find (or dont find) matching cfg row and place into that row (or
        % make a new row)
        idx_match = arrayfun(@(row) compareArgs(row, avgCfg), nexObj.UserData.T_avg.("avgCfg"));
        if any(idx_match)
            AVG_stored = nexObj.UserData.T_avg(idx_match,:).AVG{1,1};
            AVG_stored.(phase) = DF;
            nexObj.UserData.T_avg(idx_match,"AVG").AVG= {AVG_stored};
            % [nexObj.UserData.T_avg; newRow];
        else % append new row
            nexObj.UserData.T_avg = [nexObj.UserData.T_avg; newRow];
        end
    end
end