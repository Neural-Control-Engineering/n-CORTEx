function lst = move2end(lst0, strPat)
    % Find indices of the target string
    idx = find(strcmp(lst0, strPat));
    
    if ~isempty(idx)
        % Remove the target string from its original positions
        lst0(idx) = [];
        
        % Append the target string(s) at the end
        lst = [lst0, repmat({strPat}, 1, numel(idx))];
    else
        lst = lst0; % If strPat is not found, return the original list
    end
end