function out = extractEXT_AP(slrt_data, npxls_path, stim_signals, response_window_duration)
    % TODO - add session labels 
    % TODO - align spike times to all events 

    amplitudes = readNPY(strcat(npxls_path, 'amplitudes.npy'));
    % channel_map = readNPY(strcat(npxls_path, 'channel_map.npy'));
    channel_positions = readNPY(strcat(npxls_path, 'channel_positions.npy'));
    % kept_spikes = readNPY(strcat(npxls_path, 'kept_spikes.npy'));
    % ops = readNPY(strcat(npxls_path, 'ops.npy'));
    % similar_templates = readNPY(strcat(npxls_path, 'similar_templates.npy'));
    spike_clusters = readNPY(strcat(npxls_path, 'spike_clusters.npy'));
    % spike_templates = readNPY(strcat(npxls_path, 'spike_templates.npy'));
    spike_inds = readNPY(strcat(npxls_path, 'spike_times.npy'));
    templates = readNPY(strcat(npxls_path, 'templates.npy'));
    % templates_ind = readNPY(strcat(npxls_path, 'templates_ind.npy'));
    % cluster_KSLabel = readtable(strcat(npxls_path, 'cluster_KSLabel.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_ContamPct = readtable(strcat(npxls_path, 'cluster_ContamPct.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_group = readtable(strcat(npxls_path, 'cluster_group.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_Amplitude = readtable(strcat(npxls_path, 'cluster_Amplitude.tsv'), 'FileType','text','Delimiter', '\t');

    events_logical = strcmp(slrt_data(1,:).signal_types{1}(:,2), 'event');
    event_signals = slrt_data(1,:).signal_types{1}(events_logical,1);

    cluster_ids = sort(unique(spike_clusters));
    cluster_templates = zeros(length(cluster_ids), size(templates,2));
    cluster_positions = zeros(length(cluster_ids), 2);
    % wvfrm_classes = cell(length(cluster_ids),1);
    for i = 1:length(cluster_ids)
        peak_to_peaks = zeros(size(templates,3),1);
        for channel = 1:size(templates,3)
            peak_to_peaks(channel) = max(templates(i,:,channel)) - min(templates(i,:,channel));
        end
        [~, channel_ind] = max(peak_to_peaks);
        cluster_templates(i,:) = templates(i,:,channel_ind);
        cluster_positions(i,:) = channel_positions(channel_ind,:);
        % wvfrm_classes{i} = classifySpikeWvfrm(cluster_templates(i,:) * cluster_Amplitude(i,:).Amplitude, 7.0);
    end
    quality = cluster_group(:,2).KSLabel;
    cluster_info = table(cluster_ids, cluster_templates, cluster_positions, ...
        quality, cluster_Amplitude.Amplitude, cluster_ContamPct.ContamPct, ...
        'VariableNames', {'id', 'template', 'position', 'quality', ...
        'amplitude', 'contam_pct'});

    max_time = slrt_data(end,:).clock_time{1}(end);
    npxls_time = linspace(-3.5, max(max_time)+3.5, max(spike_inds));
    spike_times = npxls_time(spike_inds);
    
    % out = table('Size', [size(slrt_data,1),3],  'VariableTypes', {'double', 'cell', 'cell'}, ...
    %     'VariableNames', {'trial_num', 'spiking_data', 'cluster_info'});
    for trial = 1:size(slrt_data,1)
        % beginning, end, and stimulus time for trial 
        session_label = slrt_data(trial,:).session_label{1};
        start_time = slrt_data(trial,:).clock_time{1}(1);
        fin_time = slrt_data(trial,:).clock_time{1}(end);
        
        trial_spike_inds = find(spike_times >= start_time & spike_times <= fin_time);
        trial_spike_times = spike_times(trial_spike_inds);
        trial_spike_clusters = spike_clusters(trial_spike_inds);
        trial_spike_amplitudes = amplitudes(trial_spike_inds);

        for c = 1:length(cluster_ids)
            % basic spiking data for each cluster/trial 
            cluster_id = cluster_ids(c);
            cluster_spike_times = trial_spike_times(trial_spike_clusters == cluster_id);
            cluster_spike_amplitudes = trial_spike_amplitudes(trial_spike_clusters == cluster_id);
            
            cluster_quality = cluster_group(cluster_group(:,1).cluster_id == cluster_id, 2).KSLabel;
            row = table(cluster_id, {cluster_spike_times}, cluster_quality, {cluster_spike_amplitudes}, ...
                'VariableNames', {'cluster_id', 'spike_times', 'quality', 'spike_amplitudes'});

            % align spike times to events
            if ~isempty(cluster_spike_times)
                for es = 1:length(event_signals)
                    signal = event_signals{es};
                    if ~isnan(slrt_data(trial,:).(signal))
                        event_time = slrt_data(trial,:).clock_time{1}(slrt_data(trial,:).(signal));
                        aligned_spike_times = cluster_spike_times - event_time;
                    else
                        aligned_spike_times = [];
                    end
                    row = [row, table({aligned_spike_times}, 'VariableNames', {strcat(signal,'_aligned_spike_times')})];
                end
            else 
                for es = 1:length(event_signals)
                    signal = event_signals{es};
                    aligned_spike_times = [];
                    row = [row, table({aligned_spike_times}, 'VariableNames', {strcat(signal,'_aligned_spike_times')})];
                end
            end
            
            if c == 1
                cluster_table = row;
            else
                cluster_table = [cluster_table; row];
            end
        end
        
        if trial == 1
            out = table(trial, {session_label}, {cluster_table}, ...
                'VariableNames', {'trial_num', 'session_label', 'spiking_data'});
        else
            out = [out; table(trial, {session_label}, {cluster_table}, ...
                'VariableNames', {'trial_num', 'session_label', 'spiking_data'})];
        end
    end
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