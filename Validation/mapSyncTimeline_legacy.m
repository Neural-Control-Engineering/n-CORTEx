function t = mapSyncTimeline(syncLine, offset0)
    t = [];
    t_RE = syncLine.t_RE;
    numRisingEdges = length(t_RE);
    for i=1:numRisingEdges
        % bin samples within rising edge times (assuming delay corrected
        % from 1 Hz external pulser)
        if i < numRisingEdges
            t_RE0 = t_RE(i);
            t_RE1 = t_RE(i+1);
            T = t_RE1 - t_RE0; % cycle period
            nSamp = int32(T * Fs); % number of samples expected within a given syncCycle
            tLinSpace = linspace(t_RE0, t_RE1, double(nSamp)+2); % including points=nSamp within the endpoints
            tLinSpace = tLinSpace(2:end-1);% excluding the endpoints
            % tLinSpace = [t_RE0: T/nSamp :t_RE1]
            t = [t, tLinSpace];
        elseif  i==numRisingEdges
            t_RE0 = t_RE(i);
        end
    end
    % plot expected vs actual
    t_gt = linspace(0,t(end),Fs*t(end));
    % t_reSamp = resample(t,length(t_gt));
    figure; plot(t);hold on; plot(t_gt);
    lineFrequency_mean = 1/syncLine.IPD.mean;
    % lineFrequency_std = syncLine.IPD.std;
    title(sprintf("IPD-mapped timeline: %fHz",lineFrequency_mean));
    xlabel("samples");
    ylabel("time (s)");
end