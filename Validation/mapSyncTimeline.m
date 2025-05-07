function t = mapSyncTimeline(DF, syncLine, offset0)
    Fs = DF.meta.Fs;
    t = [];
    t_edges = syncLine.t_edges;
    t_edges_ref = syncLine.t_edges_ref;
    nSamples = size(DF.dataArray,2);

    signalTime_meta = str2double(DF.meta.fileTimeSecs);
    signalTime_calc = nSamples / DF.meta.Fs;
    
    syncOffsets = syncLine.syncOffsets;
    % align by first edge (neutralize 1st offset)
    syncOffsets(1) = 0;
    % numRisingEdges = length(t_edge);
    % synchronized timeline
    t_sync = [0, t_edges_ref, signalTime_meta] + offset0;
    t = linspace(t_sync(1), t_sync(end), nSamples);
    % len_t = length(t_sync);
    % 
    % for i=1:len_t
    %     % bin samples within rising edge times (assuming delay corrected
    %     % from 1 Hz external pulser)
    %     if i < len_t
    %         t_RE0 = t_edge(i);
    %         t_RE1 = t_edge(i+1);
    %         T = t_RE1 - t_RE0; % cycle period
    %         nSamp = int32(T * Fs); % number of samples expected within a given syncCycle
    %         tLinSpace = linspace(t_RE0, t_RE1, double(nSamp)+2); % including points=nSamp within the endpoints
    %         tLinSpace = tLinSpace(2:end-1);% excluding the endpoints
    %         % tLinSpace = [t_RE0: T/nSamp :t_RE1]
    %         t = [t, tLinSpace];
    %     elseif  i==numRisingEdges
    %         t_RE0 = t_edge(i);
    %     end
    % end
    % % apply offset0
    % % plot expected vs actual
    % t_gt = linspace(0,t(end),Fs*t(end));
    % % t_reSamp = resample(t,length(t_gt));
    % figure; plot(t);hold on; plot(t_gt);
    % lineFrequency_mean = 1/syncLine.IPD.mean;
    % % lineFrequency_std = syncLine.IPD.std;
    % title(sprintf("IPD-mapped timeline: %fHz",lineFrequency_mean));
    % xlabel("samples");
    % ylabel("time (s)");
end