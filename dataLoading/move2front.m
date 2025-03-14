function lst = move2front(lst0, strPat)
    % Find the index of the string 'SLRT'
    index = find(strcmp(lst0, strPat));
    
    % Rearrange the cell array to move 'SLRT' to the front
    if ~isempty(index)
        if lst0 ~= "SLRT"
            lst = [lst0(index); lst0([1:index-1 index+1:end])];
        else
            lst = lst0;
        end
    end
end