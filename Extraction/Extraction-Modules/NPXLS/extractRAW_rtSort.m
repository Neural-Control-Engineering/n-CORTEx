function extractRAW_rtSort(streamID, inter_path, detection_model, args)

    % CFG HEADER
    stringentThresh = args.stringentThresh; % default = 0.175
    looseThresh = args.looseThresh; % default = 0.075           

    % Run RT-Sort detection in a clean subprocess (nexus env). Embedding via
    % py.* fails: the nexus env's pyexpat links an external libexpat.dll that
    % collides with MATLAB's own libexpat.dll in-process. A subprocess has none
    % of MATLAB's DLLs loaded. detect_sequences writes rt_sort.pickle and
    % scaled_traces.npy into inter_path, which extract_rtsort reads below.
    pyVersion = "C:\Users\Primus\miniconda3\envs\nexus\python.EXE";
    rtScript  = fullfile(fileparts(mfilename('fullpath')), "runRTSort.py");
    % Cap the detection window at 5 min (300 s) to bound extraction time on long
    % recordings. runRTSort.py takes min(window_s, segment duration), so shorter
    % triggers (e.g. 11 s, 30 s) still sort in full.
    rtWindowS = 300;
    % Optional pre-trained sorter: if args.sorterPickle points at an existing
    % rt_sort.pickle, runRTSort.py sorts this trigger WITH it (LOAD mode) instead
    % of learning a fresh sorter from the (short) trigger; it falls back to
    % detection if the pickle is missing or LOAD fails. Passed as the 4th CLI arg.
    sorterPickle = "";
    if isfield(args, 'sorterPickle') && strlength(string(args.sorterPickle)) > 0
        sorterPickle = string(args.sorterPickle);
    end
    if strlength(sorterPickle) > 0
        fprintf("extractRAW_rtSort: using pre-trained sorter %s\n", sorterPickle);
        rtCmd = sprintf('"%s" "%s" "%s" "%s" %g "%s"', ...
            pyVersion, rtScript, streamID, inter_path, rtWindowS, sorterPickle);
    else
        rtCmd = sprintf('"%s" "%s" "%s" "%s" %g', pyVersion, rtScript, streamID, inter_path, rtWindowS);
    end
    [rtStatus, rtOut] = system(rtCmd);
    % Echo the subprocess stdout so the [runRTSort] mode/log lines (LOAD vs
    % detect, sequence/spike counts, any fallback) are visible on SUCCESS too —
    % otherwise they were only surfaced on error.
    fprintf("%s\n", rtOut);
    % Also persist it next to the outputs, so the LOAD-vs-detect record is
    % checkable after the fact (and when extraction runs on a parpool worker,
    % where console fprintf may not reach the main window).
    try
        logFile = fullfile(inter_path, "rtsort", "runRTSort.log");
        if ~isfolder(fullfile(inter_path, "rtsort")), mkdir(fullfile(inter_path, "rtsort")); end
        fid = fopen(logFile, "w");
        if fid > 0
            fprintf(fid, "CMD: %s\n\n%s\n", rtCmd, rtOut);
            fclose(fid);
        end
    catch
    end
    if rtStatus ~= 0
        error("extractRAW_rtSort:detectFailed", ...
            "RT-Sort subprocess failed (exit %d):\n%s", rtStatus, rtOut);
    end
    % --- Legacy embedded call (revert to this if needed) ---
    % rtsort = py.importlib.import_module("braindance.core.spikesorter.rt_sort");
    % detection_model = rtsort.ModelSpikeSorter.load_neuropixels();
    % extractors = py.importlib.import_module("spikeinterface.extractors");
    % recording = extractors.read_spikeglx(streamID, stream_id="imec0.ap");
    % spike_trains = rtsort.detect_sequences(recording, inter_path, detection_model, ...
    %     return_spikes = true, ...
    %     recording_window_ms=py.tuple({0,1*60*1000}), ...
    %     stringent_thresh=0.175, ...
    %     loose_thresh=0.075, ...
    %     inference_scaling_numerator=15.4, ...
    %     min_amp_dist_p=0.1, ...
    %     max_latency_diff_spikes=2.5, ...
    %     max_amp_median_diff_spikes=0.45, ...
    %     max_amp_median_diff_sequences=0.45, ...
    %     max_root_amp_median_std_sequences=2.5);

    % extract results (runRTSort writes its outputs into the rtsort subfolder)
    rtsortDir = fullfile(inter_path, "rtsort");
    extract_rtsort(rtsortDir);

    % Drop the bulk traces copy now that rtsort_results.mat is built.
    % scaled_traces.npy is a float16 (N_CHANS x N_SAMP) duplicate of the raw
    % recording that detect_sequences wrote only so extract_rtsort could cut
    % waveform snippets/amplitudes. rtsort_results.mat now holds everything
    % extractEXT_SPK consumes (spike trains, per-spike amps, templates, spatial
    % profiles, quality), so the copy is redundant; deleting it keeps the
    % per-trigger footprint at a few MB instead of ~1.4 GB. (runRTSort.py already
    % removed model_traces.npy / model_outputs.npy after detection.) Done here,
    % after extract_rtsort returns, so a failed extraction leaves the traces for
    % debugging and extract_rtsort itself stays a pure read-only consumer.
    scaledTraces = fullfile(rtsortDir, "scaled_traces.npy");
    if isfile(scaledTraces)
        try
            delete(strcat("\\?\", scaledTraces));
        catch ME
            warning("extractRAW_rtSort:tracesCleanup", ...
                "Could not delete %s: %s", scaledTraces, ME.message);
        end
    end
end