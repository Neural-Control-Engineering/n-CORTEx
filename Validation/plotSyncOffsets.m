% function plotSyncOffsets(syncLine, syncLine_ref)
function plotSyncOffsets(SLRT)
    % syncLines = sync.lines; syncRefLines = syncRef.lines;
    syncOffsets = measureSyncOffsets(syncLine.t_edges, syncLine_ref.t_edges, "world");
end