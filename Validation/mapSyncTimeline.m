function t_sync = mapSyncTimeline(DF, syncLine, offset0)
    preBuffLen = 3.5;
    Fs = DF.meta.Fs;
    t = [];
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
    % FIX #4: bin samples by the IMEC edge times (same frame as t_base), not the
    % SLRT reference edges. Each matched imec edge is recovered as
    % t_edges_ref(i) - syncOffsets(i) (since syncOffsets(i) = ref(i) - imec(i)),
    % which is index-aligned with syncOffsets — unlike syncLine.t_edges, which is
    % the full untrimmed set. Ref-frame boundaries against imec-frame samples
    % mis-assign a band ~offset-wide at every edge.
    te = t_edges_ref(:).';
    so = syncOffsets(:).';
    nE = min(numel(te), numel(so));
    t_imec_edges = te(1:nE) - so(1:nE);                % matched imec edges, in t_base frame
    for i = 1:nE
        t1 = t_imec_edges(i);
        if i == 1
            t0 = -preBuffLen;
        else
            t0 = t_imec_edges(i-1);
        end
        tSlice = (t_base >= t0) & (t_base <= t1);
        t_sync(tSlice) = t_base(tSlice) + so(i);
    end

    % FIX #3: extend coverage past the last edge. Beyond the last imec edge the
    % loop assigns nothing, so samples would keep raw t_base (no offset) — a step
    % discontinuity exactly where accumulated drift is largest. Hold the last
    % measured offset across the tail (constant extrapolation).
    tail = t_base > t_imec_edges(nE);
    t_sync(tail) = t_base(tail) + so(nE);

    % FIX #2: do NOT re-add offset0 here. The per-interval syncOffsets loop
    % above already maps imec -> world (it lands imec edges exactly on the SLRT
    % edges); re-adding offset0 (~syncOffsets(1)) double-counts the base offset.
    % offset0 remains an input only for backward-compatible call signatures.
    % (#3 TODO: samples beyond the last edge currently keep t_base with no
    % offset — extend coverage to close that tail discontinuity.)
    % t_sync = t_sync + offset0;
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