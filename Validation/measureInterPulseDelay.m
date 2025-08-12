function IPD = measureInterPulseDelay(t_risingEdge, groupSize)
    % pulses of B contained in A (groupwise and recordingwise)
    m=1; % group counter
    interPulseDelays = [];
    mean_tc = [];
    tcBuffer = [];
    std_tc = [];      
    for i=1:length(t_risingEdge)
        if i<length(t_risingEdge)
            t_0 = t_risingEdge(i);
            t_1 = t_risingEdge(i+1);
            ipd = t_1 - t_0;
            % accumulate results
            tcBuffer = [tcBuffer; ipd];
            interPulseDelays = [interPulseDelays; ipd];
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
    IPD.mean = mean(interPulseDelays);
    IPD.std = std(interPulseDelays);
    IPD.mean_tc = mean_tc;
    IPD.std_tc = std_tc;
end