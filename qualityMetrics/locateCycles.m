function cycleTimes = locateCycles(params, trace)
    edges = diff(trace);
    risingEdges = find(edges==1);
    cycleTimes=[];
    for i=1:length(risingEdges)-1
       cycleTimes=[cycleTimes; risingEdges(i) risingEdges(i+1)];
    end
end