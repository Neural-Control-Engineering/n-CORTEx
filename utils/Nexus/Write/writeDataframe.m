function writeDataframe(nexon, dfID, df, dtsIdx)
    % Get the BASE structure for easier reference
    base = nexon.console.BASE;
    
    % Check if dfID exists in the DTS table
    if ~any(contains(base.DTS.Properties.VariableNames, dfID))
        % If not, create a new column with the name dfID and initialize with empty cells
        base.DTS.(dfID) = cell(size(base.DTS, 1), 1);
    end
    
    % Define the condition to find the correct row
    router = base.UserData.prevRouter;
    % router=base.router;
    if isfield(router.entryParams,'subject')
        idxCond = contains(base.DTS.sessionLabel, router.entryParams.subject) & ...
                  contains(base.DTS.sessionLabel, router.entryParams.date) & ...
                  contains(base.DTS.sessionLabel, router.entryParams.phase) & ...
                  (str2double(router.entryParams.trial) == base.DTS.trialNumber);
    elseif isfield(router.entryParams,'subj')
        idxCond = contains(base.DTS.sessionLabel, router.entryParams.subj) & ...
                  contains(base.DTS.sessionLabel, router.entryParams.date) & ...
                  contains(base.DTS.sessionLabel, router.entryParams.phase) & ...
                  (str2double(router.entryParams.trial) == base.DTS.trialNumber);            
    end
          
    % Find the index of the matching row
    if isempty(dtsIdx)
        try
            dtsIdx = find(idxCond, 1);  % Get the first match
        catch e
            disp(getReport(e));
        end
    end
    % if isempty(dtsIdx)
    %     error('No matching row found in the DTS for the specified parameters.');
    % end
    
    % Write the new data entry to the specified column in the matching row
    base.DTS.(dfID){dtsIdx} = df;  % Assign the data to the correct cell
end