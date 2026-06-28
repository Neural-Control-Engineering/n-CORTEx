function t_edges_filt = filterSyncEdges(t_edges, T)
    % Remove spurious 'bounce' edges: extra edges landing a short time after a
    % true edge (ringing / contact bounce / noise), seen as inter-edge gaps far
    % smaller than the pulse period T.
    %
    % Greedy debounce: keep an edge only if it is >= minGap past the last
    % ACCEPTED edge. Anchoring on the last accepted (true) edge — rather than on
    % fixed triplets — drops an arbitrary run of consecutive bounces and stops a
    % bounce from ever being used as the reference a true edge is judged against
    % (the failure mode of the previous triplet-relative rule, which could eat a
    % true edge when bounces clustered).
    %
    % T: pulse period (1/Freq)

    minGap = T/2;                  % real edges are ~T apart; anything within half
                                   % a period of the last true edge is a bounce
    e = t_edges(:).';              % work in a row (orientation-robust)
    keep = true(1, numel(e));
    if numel(e) >= 2
        lastKept = e(1);           % first edge taken as a true edge (no prior anchor)
        for i = 2:numel(e)
            if e(i) - lastKept < minGap
                keep(i) = false;   % too close to last true edge → bounce
            else
                lastKept = e(i);
            end
        end
    end
    t_edges_filt = e(keep);
    if iscolumn(t_edges)
        t_edges_filt = t_edges_filt.';   % restore caller's orientation
    end
end
