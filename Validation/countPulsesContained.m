function PC = countPulsesContained(t_risingEdgeA, t_risingEdgeB, groupSize)
    % pulses of B contained in A (groupwise and recordingwise)
    m=1; % group counter
    risingEdgeCounts = [];
    mean_tc = [];
    tcBuffer = [];
    std_tc = [];      
    for i=1:length(t_risingEdgeA)
        if i<length(t_risingEdgeA)
            t_0 = t_risingEdgeA(i);
            t_1 = t_risingEdgeA(i+1);
            % find risingEdges (B) between t_0 and t_1
            risingEdges_B = (t_risingEdgeB > t_0) & (t_risingEdgeB < t_1);
            numRisingEdges = sum(risingEdges_B);
            % accumulate results
            tcBuffer = [tcBuffer; numRisingEdges];
            risingEdgeCounts = [risingEdgeCounts; numRisingEdges];
            if m == groupSize
                mean_tc = [mean_tc; mean(tcBuffer)];
                std_tc = [std_tc; std(tcBuffer)];
                tcBuffer = [];
                m=1;
            else
                m = m+1;
            end
        end
    end
    PC.mean = mean(risingEdgeCounts);
    PC.std = std(risingEdgeCounts);
    PC.mean_tc = mean_tc;
    PC.std_tc = std_tc;
end