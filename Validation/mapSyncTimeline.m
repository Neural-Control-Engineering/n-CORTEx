function t_sync = mapSyncTimeline(DF, syncLine, offset0)
    preBuffLen = 3.5;
    Fs = DF.meta.Fs;
    t = [];
    t_edges = syncLine.t_edges - preBuffLen;
    t_edges_ref = syncLine.t_edges_ref - preBuffLen;
    nSamples = size(DF.dataArray,2);

    signalTime_meta = str2double(DF.meta.fileTimeSecs);
    signalTime_calc = nSamples / DF.meta.Fs;
    
    % t_base0 = linspace(-preBuffLen,str2double(DF.meta.fileTimeSecs)-preBuffLen,nSamples);
    % t_base1 = [1:nSamples]./Fs - preBuffLen;
    t_base = linspace(0, nSamples/Fs, nSamples) - preBuffLen;
    t_sync = t_base;
    syncOffsets = syncLine.syncOffsets;
    %% Apply second-wise offset correction
    for i = 1:length(t_edges_ref)
        % time boundaries
        t1 = t_edges_ref(i);
        if i == 1
            t0 = -preBuffLen;
        else
            t0 = t_edges_ref(i-1);
        end
        % apply localized offset
        tSlice = (t_base >= t0) & (t_base <= t1);
        offset_local = syncOffsets(i);
        t_sync(tSlice) = t_base(tSlice) + offset_local;
    end

    t_sync = t_sync + offset0;
    % align by first edge (neutralize 1st offset)
    % syncOffsets(1) = 0;
    % numRisingEdges = length(t_edge);
    % synchronized timeline
    % t_sync = [0, t_edges_ref, signalTime_meta] + offset0;
    % t = linspace(t_start, t_stop, nSamples);
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