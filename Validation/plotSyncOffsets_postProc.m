function plotSyncOffsets_postProc(syncLine, syncLine_ref, sessionDetails) 
    % syncOffsets = measureSyncOffsets(syncLine.t_edges, syncLine_ref.t_edges, syncLine.t_insert, syncLine_ref.t_insert, "world");
    figure; xline(syncLine.t_edges,"red"); hold on; xline(syncLine_ref.t_edges,"blue");
    if ~isempty(syncLine.t_insert)
        xline(syncLine.t_insert,"green"); xline(syncLine_ref.t_insert,"cyan");
    end
    title(sprintf("%s--%d",sessionDetails.sessionLabel,sessionDetails.t));
    hold off;
    figure; plot(syncLine.insertOffsets);
    title(sprintf("%s--%d",sessionDetails.sessionLabel,sessionDetails.t));
    % figure; plot(syncLine.t_edges, syncOffsets);
    
end