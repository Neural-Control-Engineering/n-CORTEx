function stackTall(loc, T)
    % recover existing array 
    tableDir = dir(loc); 
    % check if folder has items
    if length(tableDir)>2
        T_pre = loadTall(loc);
    else
        T_pre = [];
    end    
end