function sortObj = initRTSort(params, recording, inter_path, detection_model, window)
    % detection_model = C:\Code_Repo\n-CORTEx\utils\BrainDance\braindance\core\spikedetector\detection_models\neuropixels
    pyVersion = "C:\Users\Primus\anaconda3\envs\RTSort\python.EXE";
    pyenv(Version=pyVersion)
    if isempty(recording)
        % recording = fullfile("C:\Users\Primus\000004\sub-TWH107","sub-TWH107_ses-20181201_ecephys+image.nwb")
        % recording = fullfile(params.paths.Data.RAW.NPXLS.local,"sim_g0/sim_g0_imec0/");
        % recording = fullfile(params.paths.Data.RAW.NPXLS.local,"date--2024-03-10_subj--6736-20240310_phase--implant_g0/date--2024-03-10_subj--6736-20240310_phase--implant_g0_imec0");
        % recording = fullfile(params.paths.Data.RAW.NPXLS.local,"date--2024-05-22_subj---_phase--implant_g0\date--2024-05-22_subj---_phase--implant_g0_imec0");
        % recording = fullfile(params.paths.Data.RAW.NPXLS.local,"date--2024-03-12_subj--6736-20240310_npxls--R-npx10_phase--L-hind-paw_g0/date--2024-03-12_subj--6736-20240310_npxls--R-npx10_phase--L-hind-paw_g0_imec0/");
        recording = fullfile(params.paths.Data.RAW.NPXLS.local,"RTSort_g0/RTSort_g0_imec0/");
    end
    if isempty(detection_model)
        detection_model = fullfile(params.paths.repo_path,"utils","BrainDance/braindance/core/spikedetector/detection_models/neuropixels");
    end
    if isempty(inter_path)
        hostName = getHostName;
        if ispc
            inter_path = fullfile("C:","npxlsTemp");
        elseif isunix            
            inter_path = fullfile("home/",hostName,"npxlsTemp");
        end
    end
    
    cd(fullfile(params.paths.repo_path,"utils/BrainDance/braindance/core/spikesorter/"))
    % mod1 = py.importlib.import_module("maxwell_env")
    % mod2 = py.importlib.import_module("sort")
    % spikeInterface = py.importlib.import_module("spikeinterface")
    extractors = py.importlib.import_module("spikeinterface.extractors");
    recording = extractors.read_spikeglx(recording,stream_id="imec0.ap")
    rtSortMod = py.importlib.import_module("rt_sort")
    % cd("C:\Code_Repo\n-CORTEx\utils\BrainDance\braindance\core\spikedetector")
    % spikeSorterModel = py.importlib.import_module("model2")
    % detection_model = spikeSorterModel.ModelSpikeSorter.load(detection_model);
    % npxlsParams = rtSortMod.neuropixels_params;
    % sortObj = rtSortMod.detect_sequences(recording,inter_path, detection_model)
    sortObj = rtSortMod.detect_sequences(recording, inter_path, detection_model, ...        
        recording_window_ms=py.tuple({0,1*60*1000}), ...
        stringent_thresh=0.175, ...
        loose_thresh=0.075, ...
        inference_scaling_numerator=15.4, ...
        min_amp_dist_p=0.1, ...
        max_latency_diff_spikes=2.5, ...
        max_amp_median_diff_spikes=0.45, ...
        max_amp_median_diff_sequences=0.45, ...
        max_root_amp_median_std_sequences=2.5)

    rtSortObj = sortObj;
    rtSortObj.reset();
    obs = readDataMod(modSrv, 1000);
    rtSortObj.running_sort(obs(:,1:384))
    spikeTrains = sortObj.seq_spike_trains;
    seqs_inner_loose_elecs = sortObj.seqs_inner_loose_elecs;
    locs = sortObj.seq_locs;
    
end