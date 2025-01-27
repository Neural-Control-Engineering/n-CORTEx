function out = extAP(SLRT, npxls_path)
    % DONE - add session labels 
    % DONE - align spike times to all events 
    % DONE - merge spiking data and cluster info
         
    amplitudes = readNPY(fullfile(npxls_path, 'amplitudes.npy'));
    % channel_map = readNPY(strcat(npxls_path, 'channel_map.npy'));
    channel_positions = readNPY(fullfile(npxls_path, 'channel_positions.npy'));
    % kept_spikes = readNPY(strcat(npxls_path, 'kept_spikes.npy'));
    % ops = readNPY(strcat(npxls_path, 'ops.npy'));
    % similar_templates = readNPY(strcat(npxls_path, 'similar_templates.npy'));
    spike_clusters = readNPY(fullfile(npxls_path, 'spike_clusters.npy'));
    % spike_templates = readNPY(strcat(npxls_path, 'spike_templates.npy'));
    spike_inds = readNPY(fullfile(npxls_path, 'spike_times.npy'));
    templates = readNPY(fullfile(npxls_path, 'templates.npy'));
    % templates_ind = readNPY(strcat(npxls_path, 'templates_ind.npy'));
    % cluster_KSLabel = readtable(strcat(npxls_path, 'cluster_KSLabel.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_ContamPct = readtable(fullfile(npxls_path, 'cluster_ContamPct.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_group = readtable(fullfile(npxls_path, 'cluster_group.tsv'), 'FileType','text','Delimiter', '\t');
    cluster_Amplitude = readtable(fullfile(npxls_path, 'cluster_Amplitude.tsv'), 'FileType','text','Delimiter', '\t');

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
        quality{i} = cluster_group(cluster_group(:,1).cluster_id == cluster_ids(i),2).KSLabel;
        cluster_amplitude(i) = cluster_Amplitude(cluster_Amplitude(:,1).cluster_id == cluster_ids(i),2).Amplitude;
        cluster_contamPct(i) = cluster_ContamPct(cluster_ContamPct(:,1).cluster_id == cluster_ids(i),2).ContamPct;
    end
    
    cluster_info = table(cluster_ids, cluster_templates, cluster_positions, ...
        quality, cluster_amplitude, cluster_contamPct, cluster_channel, ...
        'VariableNames', {'id', 'template', 'position', 'quality', ...
        'amplitude', 'contam_pct', 'channel'});

    max_time = SLRT(end,:).clock_time{1}(end);
    % % npxls_time = linspace(-3.5, max(max_time)+3.5, max(spike_inds));
    % npxls_time = linspace(-3.5, max(max_time)+3.5, 30000 * max_time + 7); Fs
    % % (30K) * (max(max_time) + 7.0)
    spike_inds = spike_inds(spike_inds > 0);
    npxls_time = linspace(-3.5, max(max_time)+3.5, max(spike_inds));
    spike_times = npxls_time(spike_inds);
    
    for trial = 1:size(SLRT,1)
        % beginning, end, and stimulus time for trial 
        session_label = SLRT(trial,:).session_label{1};
        start_time = SLRT(trial,:).clock_time{1}(1);
        fin_time = SLRT(trial,:).clock_time{1}(end);
        
        trial_spike_inds = find(spike_times >= (start_time-3.5) & spike_times <= (fin_time+5.0));
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
                {cluster_info(c,:).template}, {cluster_info(c,:).channel}, ...
                'VariableNames', {'cluster_id', 'spike_times', 'quality', 'spike_amplitudes', ...
                'template_amplitude', 'position', 'contam_pct', 'template', 'channel'});

            % align spike times to events
            if ~isempty(cluster_spike_times)
                for es = 1:length(event_signals)
                    signal = event_signals{es};
                    if ~isnan(SLRT(trial,:).(signal))
                        event_time = SLRT(trial,:).clock_time{1}(SLRT(trial,:).(signal));
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

        if trial == 1
            out = table(trial, {session_label}, {cluster_table}, ...
                'VariableNames', {'trial_num', 'session_label', 'spiking_data'});
        else
            out = [out; table(trial, {session_label}, {cluster_table}, ...
                'VariableNames', {'trial_num', 'session_label', 'spiking_data'})];
        end
    end
end