function extractRAW_rtSort(streamID, inter_path, detection_model, args)

    % CFG HEADER
    stringentThresh = args.stringentThresh; % default = 0.175
    looseThresh = args.loose_thresh; % default = 0.075           

    rtsort = py.importlib.import_module("braindance.core.spikesorter.rt_sort");    
    detection_model = rtsort.ModelSpikeSorter.load_neuropixels();
    % loead recording
    extractors = py.importlib.import_module("spikeinterface.extractors");
    recording = extractors.read_spikeglx(streamID, stream_id="imec0.ap");
    spike_trains = rtsort.detect_sequences(recording, inter_path, detection_model, ...
        return_spikes = true, ...
        recording_window_ms=py.tuple({0,1*60*1000}), ...
        stringent_thresh=0.175, ...
        loose_thresh=0.075, ...
        inference_scaling_numerator=15.4, ...
        min_amp_dist_p=0.1, ...
        max_latency_diff_spikes=2.5, ...
        max_amp_median_diff_spikes=0.45, ...
        max_amp_median_diff_sequences=0.45, ...
        max_root_amp_median_std_sequences=2.5);

    spikes = double(spike_trains.astype(py.numpy.float64));
    spike_trains.dtype    
    spike_list = py.list(spike_trains);     
    nUnits     = int32(py.len(spike_list));     
    spikes     = cell(nUnits, 1);                                                         
    for k = 1:nUnits
      spikes{k} = double(spike_list{k}.astype(py.numpy.float64));                       
    end  
    % sequence_spike_trains = rtsort.sort_offline(recording, inter_path, verbose=true)

    % extract results
    extract_rtsort(inter_path);
end