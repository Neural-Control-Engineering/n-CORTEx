function AP = extAP(SLRT, npxls_path, trigNum)
    % DONE - add session labels 
    % DONE - align spike times to all events 
    % DONE - merge spiking data and cluster info
    
    % DEFINE    
    % Fs = 30000;
    % nChans = 385;

    % load sync data (from RAW layer)
    load(fullfile(npxls_path,"sync.mat"),'sync'); % time vectors and QC meta analysis for cross-device sync pulses    
    load(fullfile(npxls_path,"lfp.mat"),'lfp');
    load(fullfile(npxls_path,"ap.mat"),'ap');
    preBuffLen = str2double(ap.meta.trgTTLMarginS); % seconds
    postBuffLen = preBuffLen; % seconds
    % meta fields:
    % first sample
    firstSample = str2double(lfp.meta.firstSample);
    Fs_original = str2double(lfp.meta.imSampRate);
    t_start = firstSample / Fs_original; % seconds prior to recording
    % load spiking data (kilosort output)
    kilosort_path = fullfile(npxls_path,"kilosort4");
    amplitudes = readNPY(fullfile(kilosort_path, 'amplitudes.npy'));
    % channel_map = readNPY(strcat(kilosort_path, 'channel_map.npy'));
    channel_positions = readNPY(fullfile(kilosort_path, 'channel_positions.npy'));
    % kept_spikes = readNPY(strcat(kilosort_path, 'kept_spikes.npy'));
    % ops = readNPY(strcat(kilosort_path, 'ops.npy'));
    % similar_templates = readNPY(strcat(kilosort_path, 'similar_templates.npy'));
    spike_clusters = readNPY(fullfile(kilosort_path, 'spike_clusters.npy'));
    % spike_templates = readNPY(strcat(kilosort_path, 'spike_templates.npy'));
    spike_inds = readNPY(fullfile(kilosort_path, 'spike_times.npy'));
    templates = readNPY(fullfile(kilosort_path, 'templates.npy'));
    % templates_ind = readNPY(strcat(kilosort_path, 'templates_ind.npy'));
    % cluster_KSLabel = readtable(strcat(kilosort_path, 'cluster_KSLabel.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_ContamPct = readtable(fullfile(kilosort_path, 'cluster_ContamPct.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_group = readtable(fullfile(kilosort_path, 'cluster_group.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_Amplitude = readtable(fullfile(kilosort_path, 'cluster_Amplitude.tsv'), 'FileType','text','Delimiter', '\t');

    events_logical = strcmp(SLRT(1,:).signal_types{1}(:,2), 'event');
    event_signals = SLRT(1,:).signal_types{1}(events_logical,1);

    cluster_ids = sort(unique(spike_clusters));
    cluster_templates = zeros(length(cluster_ids), size(templates,2));
    cluster_positions = zeros(length(cluster_ids), 2);
    wvfrm_classes = cell(length(cluster_ids),1);
    quality = cell(length(cluster_ids),1);
    cluster_channel = zeros(length(cluster_ids),1);
    cluster_amplitude = zeros(length(cluster_ids),1);
    cluster_contamPct = zeros(length(cluster_ids),1);
    for i = 1:length(cluster_ids)
        peak_to_peaks = zeros(size(templates,3),1);
        for channel = 1:size(templates,3)
            peak_to_peaks(channel) = max(templates(i,:,channel)) - min(templates(i,:,channel));
        end
        [~, channel_ind] = max(peak_to_peaks);
        cluster_templates(i,:) = templates(cluster_group(:,1).cluster_id == cluster_ids(i),:,channel_ind);
        cluster_positions(i,:) = channel_positions(channel_ind,:);
        cluster_channel(i) = channel_ind;
        wvfrm_classes{i} = classifySpikeWvfrm(cluster_templates(i,:) * cluster_Amplitude(i,:).Amplitude, 7.0);
        quality{i} = cluster_group(cluster_group(:,1).cluster_id == cluster_ids(i),2).KSLabel;
        cluster_amplitude(i) = cluster_Amplitude(cluster_Amplitude(:,1).cluster_id == cluster_ids(i),2).Amplitude;
        cluster_contamPct(i) = cluster_ContamPct(cluster_ContamPct(:,1).cluster_id == cluster_ids(i),2).ContamPct;
    end
    
    cluster_info = table(cluster_ids, cluster_templates, cluster_positions, ...
        quality, cluster_amplitude, cluster_contamPct, wvfrm_classes, cluster_channel, ...
        'VariableNames', {'id', 'template', 'position', 'quality', ...
        'amplitude', 'contam_pct', 'waveform_class', 'channel'});

    % max_time = SLRT(end,:).("trial-gate_clock_time"){1}(end);
    idx_latestSpike = max(spike_inds);
    % max_time = round(idx_latestSpike,3,"significant")
    max_time = ceil(idx_latestSpike / 10000) * 10000; % latest-recorded AP; round up from the nearest 10K    
    % npxls_time = linspace(-3.5, max(max_time)+3.5, max(spike_inds));
    % npxls_time = linspace(-3.5, max(max_time)+3.5, 30000 * max_time + 7); Fs
    % (30K) * (max(max_time) + 7.0)
    % spike_times = npxls_time(spike_inds);
    % t_ap = linspace(-preBuffLen, max(max_time)+postBuffLen, Fs * max_time + 7);
    % t_ap = linspace(0, double(max_time/Fs), max_time) - preBuffLen;
    % t_ap = [0: max_time] ./ Fs; - preBuffLen;
    nSamples = (str2double(ap.meta.fileSizeBytes) / str2double(ap.meta.nSavedChans)) / 2; % two bytes per sample (16 bit precision)
    ap.dataArray = ones([1,nSamples]);
    ap.meta.Fs = str2double(ap.meta.imSampRate);
    sync_ref = constructSync_slrt(SLRT);
    sync = extractSyncOffset(sync_ref.lines.sync_1Hz_slrt, sync, t_start);
    t_ap = mapSyncTimeline(ap, sync.lines.sync_1Hz_imec, sync.lines.sync_1Hz_imec.offset0);
    spike_times = t_ap(spike_inds(spike_inds>0)); % for now: ignore negative spike inds
    spike_clusters = spike_clusters(spike_inds>0);
    
    % out = table('Size', [size(slrt_data,1),3],  'VariableTypes', {'double', 'cell', 'cell'}, ...
    %     'VariableNames', {'trial_num', 'spiking_data', 'cluster_info'});
    out = [];
    % prevSyncOffset = [];
    for trial = 1:size(SLRT,1)
        % only apply to SLRT trials matching trigNum
        trialGate = SLRT(trial,:).("trial-gate"){1}; % find which acquisition gate
        if trialGate == trigNum
            % row_SLRT = SLRT(trial,:);            
            % trial-wise temporal offset tracking 
            % [syncOffset, sync_adj] = extractSyncOffset(row_SLRT, sync, prevSyncOffset);
            % sync = extractSyncOffset(row_SLRT, sync, prevSyncOffset, t_start);
            % simulate data array matching number of imec samples
            % (spiking)
            % data)
            % nSamples = (str2double(ap.meta.fileSizeBytes) / str2double(ap.meta.nSavedChans)) / 2; % two bytes per sample (16 bit precision)
            % ap.dataArray = ones([1,nSamples]);
            % ap.meta.Fs = str2double(ap.meta.imSampRate);
            % t_ap = mapSyncTimeline(ap, sync.lines.sync_1Hz_imec, sync.lines.sync_1Hz_imec.offset0);
            % t_ap = mapSyncTimeline(sync_adj.lines.sync_250Hz,Fs);
            % t_ap_1Hz = mapSyncTimeline(sync_adj.lines.sync_1Hz,Fs);
            % prevSyncOffset = syncOffset; % update prevSyncOffset for next itr
            % beginning, end, and stimulus time for trial 
            session_label = SLRT(trial,:).session_label{1};
            start_time = SLRT(trial,:).("trial-gate_clock_time"){1}(1);
            fin_time = SLRT(trial,:).("trial-gate_clock_time"){1}(end);
            
            % trial_spike_inds = find(spike_times >= (start_time-3.5) & spike_times <= (fin_time+5.0));            
            trial_spike_inds = find(spike_times >= (start_time) & spike_times <= (fin_time+postBuffLen));
            trial_spike_times = spike_times(trial_spike_inds);
            trial_spike_clusters = spike_clusters(trial_spike_inds);
            trial_spike_amplitudes = amplitudes(trial_spike_inds);
    
            for c = 1:size(cluster_info,1)
                % basic spiking data for each cluster/trial 
                cluster_id = cluster_info(c,:).id;
                cluster_spike_times = trial_spike_times(trial_spike_clusters == cluster_id);
                cluster_spike_amplitudes = trial_spike_amplitudes(trial_spike_clusters == cluster_id);
                
                cluster_quality = cluster_group(cluster_group(:,1).cluster_id == cluster_id, 2).KSLabel;
                row = table(cluster_id, {cluster_spike_times}, cluster_quality, {cluster_spike_amplitudes}, ...
                    cluster_info(c,:).amplitude, {cluster_info(c,:).position}, cluster_info(c,:).contam_pct, ...
                    {cluster_info(c,:).waveform_class}, {cluster_info(c,:).template}, {cluster_info(c,:).channel}, ...
                    'VariableNames', {'cluster_id', 'spike_times', 'quality', 'spike_amplitudes', ...
                    'template_amplitude', 'position', 'contam_pct', 'waveform_class', 'template', 'channel'});                
    
                % align spike times to events (including sync pulse)
                if ~isempty(cluster_spike_times)
                    for es = 1:length(event_signals)
                        signal = event_signals{es};
                        if ~isnan(SLRT(trial,:).(signal))
                            event_time = SLRT(trial,:).("trial-gate_clock_time"){1}(SLRT(trial,:).(signal));
                            peri_trial_spike_inds = find(spike_times >= (event_time-3.5) & spike_times <= (event_time+5));
                            peri_trial_spike_times = spike_times(peri_trial_spike_inds);
                            peri_trial_spike_clusters = spike_clusters(peri_trial_spike_inds);
                            ptcst = peri_trial_spike_times(peri_trial_spike_clusters == cluster_id);
                            aligned_pscst = ptcst - event_time;
                        else
                            aligned_pscst = [];
                        end
                        row = [row, table({aligned_pscst}, ...
                            'VariableNames', {strcat(signal,'_aligned_spike_times')})];
                    end
                else 
                    for es = 1:length(event_signals)
                        signal = event_signals{es};
                        aligned_pscst = [];
                        row = [row, table({aligned_pscst}, ...
                            'VariableNames', {strcat(signal,'_aligned_spike_times')})];
                    end
                end
                
                if c == 1
                    cluster_table = row;
                else
                    cluster_table = [cluster_table; row];
                end
            end

            % store offset (excluded as duplicate of ext-AP)
            % row = [row, table({sync},'VariableNames',{'syncOffset_ap'})];

            if trial == 1
                out = table(trial, {session_label}, {cluster_table}, ...
                    'VariableNames', {'trial_num', 'session_label', 'spiking_data'});
            else
                out = [out; table(trial, {session_label}, {cluster_table}, ...
                    'VariableNames', {'trial_num', 'session_label', 'spiking_data'})];
            end
        end
    end

    AP = out;
end

function out = classifySpikeWvfrm(wvfrm, fsRsThreshold)
    [neg_amp, neg_ind] = max(abs(wvfrm));
    if wvfrm(neg_ind) > 0
        out = 'PS';
    else
        [width, first_ind, last_ind, half_max] = getSpikeWidth(wvfrm);
        [pks, locs] = findpeaks(wvfrm, 'MinPeakProminence', 1);
        if ~isempty(pks) && locs(1) < neg_ind
            if length(locs(locs < neg_ind)) > 1
                [first_peak, fp_ind] = max(pks(locs < neg_ind));
                try
                    nplocs = locs(locs > neg_ind);
                    np_ind = nplocs(1);
                catch
                    [~, np_ind] = max(wvfrm(neg_ind+1:end));
                    np_ind = np_ind + neg_ind;
                end
            else
                first_peak = pks(1);
                fp_ind = locs(1);
                try
                    np_ind = locs(2);
                catch
                    [~, np_ind] = max(wvfrm(neg_ind+1:end));
                    np_ind = np_ind + neg_ind;
                end
            end
            if (first_peak >= 0.1*neg_amp) 
                if width < 20
                    out = 'TS';
                else
                    out = 'CS';
                end
            else 
                if width < fsRsThreshold
                    out = 'FS';
                else
                    out = 'RS';
                end
            end
        else
            if width < fsRsThreshold
                out = 'FS';
            else
                out = 'RS';
            end
        end
    end
end

function [out, first_ind, last_ind, half_max] = getSpikeWidth(wvfrm)
    y = abs(wvfrm);
    x1 = 1:length(wvfrm);
    x2 = 1:0.25:length(wvfrm);
    y = spline(x1, y, x2);
    [amp, ind] = max(y);
    half_max = amp / 4;
    first_ind = find(y(1:ind) <= half_max, 1, 'last');
    last_ind = find(y(ind+1:end) <= half_max, 1, 'first') + ind;
    first_ind = x2(first_ind);
    last_ind = x2(last_ind);
    out = last_ind - first_ind;
    % figure(); plot(y); hold on; plot([first_ind, last_ind],[half_max, half_max], 'k--')
end