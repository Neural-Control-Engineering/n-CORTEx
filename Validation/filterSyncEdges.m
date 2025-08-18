function t_edges_filt = filterSyncEdges(t_edges, T)
    % remove spurious rising edges
    % such as:
    % immediated 'bounce' edges within a short duration of a true edge
    % ...
    % T: pulse period (1/Freq)
    
    firstEdges = t_edges(1:end-2);
    secondEdges = t_edges(2:end-1);
    thirdEdges = t_edges(3:end);
    firstDif = (secondEdges-firstEdges);
    secondDif = (thirdEdges-firstEdges);
    difs = [firstDif', secondDif'];
    % subtract T to find min dist
    T_removed = arrayfun(@(x) x-T, difs);
    % compress into cell-wise vectors
    T_removed_cell = mat2cell(T_removed, ones(size(T_removed,1),1), size(T_removed,2));
    [mins, idx_mins] = cellfun(@(x, idx) (min(abs(x))), T_removed_cell, "UniformOutput", true);
    % find where third diff is favored
    idx_bounce = find(idx_mins==2)+1;
    % idx_bounce = diff(idx_mins)
    % removed one 'right' from this index
    t_edges_filt = t_edges;
    t_edges_filt(idx_bounce)=[];
end