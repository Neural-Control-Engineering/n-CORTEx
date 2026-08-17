# CLI wrapper so MATLAB can run RT-Sort detection in a clean subprocess,
# avoiding the nexus-env libexpat.dll vs MATLAB libexpat.dll in-process
# collision. Mirrors the embedded call in extractRAW_rtSort.m.
#
# Output convention (analogous to kilosort4): everything is written into an
# "rtsort" subfolder of inter_path. The raw .ap.bin is never moved, linked, or
# duplicated -- to sort only the one trigger MATLAB specified, we read the whole
# imec folder and select that trigger's segment in memory (SpikeGLX triggers map
# to segments in ascending trigger order). rtsort/ ends up holding only outputs
# (rt_sort.pickle, scaled_traces.npy, rtsort_fields.mat) for extract_rtsort.m.
import math
import os
import re
import sys
import numpy as np
import probeinterface as pi
from scipy.io import savemat
from braindance.core.spikesorter.rt_sort import detect_sequences, ModelSpikeSorter
from spikeinterface.extractors import read_spikeglx

# Phase3A SpikeGLX metas lack the probe-type annotation that
# SpikeGLXRecordingExtractor expects (it uses it only to compute ADC
# inter-sample shifts). probeinterface still builds the probe geometry fine, so
# we inject the NP1.0-family type (0) -- Phase3A shares the 1.0 ADC readout (12
# channels/ADC) -- so read_spikeglx can finish. The key name differs by
# spikeinterface version ('probe_type' in >=0.100, 'imDatPrb_type' before), so
# set both. No-op for probes that already carry the annotation.
_orig_pi_read_spikeglx = pi.read_spikeglx


def _pi_read_spikeglx_compat(meta_filename):
    probe = _orig_pi_read_spikeglx(meta_filename)
    probe.annotations.setdefault("probe_type", 0)
    probe.annotations.setdefault("imDatPrb_type", 0)
    return probe


pi.read_spikeglx = _pi_read_spikeglx_compat

_KEY_RE = re.compile(r"_g(\d+)_t(\d+)\.imec\d*\.ap\.bin$")


def _to_numpy(x):
    """torch tensor / list / array -> float64 numpy array."""
    if hasattr(x, "detach"):
        x = x.detach().cpu().numpy()
    return np.asarray(x, dtype=np.float64)


# --- Coat-check analogy for what this function does ---------------------------
# Loading the folder hands us EVERY trigger stacked into one recording, and the
# loader only fetches a piece back by *position* (segment 0, 1, 2, ...), never by
# its trigger name. Think of a coat check: your file's name tag says "trigger t3",
# but the attendant (select_segments) only accepts a hook NUMBER. So we replay the
# loader's own filing rule -- take the (gate, trigger) tags actually handed in,
# sort them, and find where ours sits -- to translate "t3" into "hook N", then ask
# for hook N. The (g,t) tuple never reaches select_segments: keys.index(...)
# consumes it and returns the integer N; select_segments sees only N. Before
# trusting the translation we count coats-on-rack (segments) vs tags-we-saw
# (keys); if they disagree we refuse to guess a hook rather than risk handing back
# the wrong coat.
# ------------------------------------------------------------------------------
def _select_trigger(recording, bin_path):
    """Select only the (gate, trigger) named in bin_path without touching the raw
    .bin. read_spikeglx loads the whole imec folder as a multi-segment recording;
    neo (spikeglxrawio.scan_files) assigns each segment index by the position of
    its (gate_num, trigger_num) integer key in the numerically sorted set of keys.
    We reconstruct that same sorted key list from the folder and select the
    matching segment. Matching on (gate, trigger) -- not trigger alone -- keeps the
    pick correct when more than one gate is present (trigger t1 exists under both
    g0 and g1)."""
    n_seg = recording.get_num_segments()
    if n_seg == 1:
        return recording
    m = _KEY_RE.search(os.path.basename(bin_path))
    if m is None:
        return recording
    target_key = (int(m.group(1)), int(m.group(2)))
    folder = os.path.dirname(os.path.abspath(bin_path))
    keys = sorted({(int(mm.group(1)), int(mm.group(2)))
                   for f in os.listdir(folder)
                   for mm in [_KEY_RE.search(f)] if mm})
    # Our key list is rebuilt from *.ap.bin in this folder; neo builds segments by
    # recursively scanning every .meta/.bin pair (any stream) and de-duping on
    # (gate, trigger). The two agree for the standard single-gate, ap+lf-per-
    # trigger layout, but diverge if a trigger has a .meta neo counts yet no
    # .ap.bin here (e.g. lf-only), if extra metas are nested in the tree, or if
    # the folder spans more gates than we enumerated. In any such case an
    # index-based select_segments would silently pick the wrong epoch -- refuse to
    # guess instead.
    if len(keys) != n_seg:
        raise ValueError(
            f"Reconstructed {len(keys)} (gate,trigger) key(s) {keys} from *.ap.bin "
            f"in {folder}, but the recording has {n_seg} segments -- segment order "
            f"cannot be safely inferred; refusing to guess which segment is "
            f"{target_key}.")
    if target_key not in keys:
        raise ValueError(f"(gate,trigger) {target_key} not found among {keys} in {folder}")
    return recording.select_segments([keys.index(target_key)])


def export_fields(out_dir, obj=None, spike_trains_override=None):
    """Export the fields extract_rtsort.m needs as a plain .mat (ragged spike
    trains become a MATLAB cell via an object array).

    obj                   : the RTSort sorter. None → load out_dir/rt_sort.pickle
                            (DETECT mode, where the just-detected pickle lives there).
    spike_trains_override : per-sequence spike-time arrays (ms) to use instead of
                            obj.seq_spike_trains. LOAD mode passes the trains from
                            sort_offline on the trigger so the unit DESCRIPTIONS come
                            from the pre-trained sorter but the SPIKES are the trial's.
    """
    if obj is None:
        import pickle
        pickle_path = os.path.join(out_dir, "rt_sort.pickle")
        with open(pickle_path, "rb") as fh:
            obj = pickle.load(fh)

    src_trains = obj.seq_spike_trains if spike_trains_override is None else spike_trains_override
    spike_trains = np.empty((len(src_trains),), dtype=object)
    for i, st in enumerate(src_trains):
        spike_trains[i] = _to_numpy(st).ravel()

    fields = {
        "num_seqs": int(obj.num_seqs),
        "num_elecs": int(obj.num_elecs),
        "seq_n_before": int(obj.seq_n_before),
        "seq_n_after": int(obj.seq_n_after),
        "seq_spike_trains": spike_trains,
        "seq_locs": _to_numpy(obj.seq_locs),
        "seq_root_elecs": _to_numpy(list(obj._seq_root_elecs)),
        "seqs_root_amp_means": _to_numpy(obj.seqs_root_amp_means),
        "seqs_root_amp_stds": _to_numpy(obj.seqs_root_amp_stds),
        "seqs_amps": _to_numpy(obj.seqs_amps),
        "seqs_latencies": _to_numpy(obj.seqs_latencies),
        "comp_elecs_flattened": _to_numpy(obj.comp_elecs_flattened),
    }
    savemat(os.path.join(out_dir, "rtsort_fields.mat"), fields, do_compression=True)


def runRTSort(file_path, inter_path, window_s=None):
    rtsort_dir = os.path.join(inter_path, "rtsort")
    os.makedirs(rtsort_dir, exist_ok=True)
    # Self-report the compute device (subprocess stdout is captured by
    # extractRAW_rtSort.m). braindance's detect_sequences hardcodes device="cuda"
    # with no CPU fallback, so RT-Sort cannot silently run on CPU -- it errors if
    # CUDA is unavailable. This line surfaces that up front instead of mid-run.
    import torch
    if torch.cuda.is_available():
        print(f"[runRTSort] device=cuda ({torch.cuda.get_device_name(0)}); "
              f"torch {torch.__version__}", flush=True)
    else:
        print("[runRTSort] WARNING: CUDA not available -- detect_sequences forces "
              "device='cuda' (no CPU fallback) and will error below.", flush=True)
    detection_model = ModelSpikeSorter.load_neuropixels()
    folder = os.path.dirname(os.path.abspath(file_path))
    recording = read_spikeglx(folder, stream_id="imec0.ap")
    recording = _select_trigger(recording, file_path)
    # Detect over the full segment. braindance allocates the on-disk traces
    # buffer from recording_window_ms, but get_traces() clamps to the real
    # length -- if the requested window is longer than the segment (e.g. a 60 s
    # window vs an 11 s trigger) the buffer is over-sized and _save_traces_si
    # raises "could not broadcast ... into ...". Setting the window to the
    # segment duration keeps window <= segment; floor() keeps
    # round(end_ms * samp_freq) <= total samples. (Tradeoff: buffer/mem/time now
    # scale with the full recording length -- reinstate a min(cap, ...) here to
    # bound very long recordings.)
    dur_ms = recording.get_total_samples() / recording.get_sampling_frequency() * 1000.0
    if window_s is None:
        window_end_ms = math.floor(dur_ms)          # full segment (default)
    else:
        window_end_ms = min(window_s * 1000.0, math.floor(dur_ms))  # optional cap
    detect_sequences(
        recording, rtsort_dir, detection_model,
        return_spikes=True,
        recording_window_ms=(0, window_end_ms),
        stringent_thresh=0.175,
        loose_thresh=0.075,
        inference_scaling_numerator=15.4,
        min_amp_dist_p=0.1,
        max_latency_diff_spikes=2.5,
        max_amp_median_diff_spikes=0.45,
        max_amp_median_diff_sequences=0.45,
        max_root_amp_median_std_sequences=2.5,
    )
    export_fields(rtsort_dir)
    # Drop the bulk intermediates. model_traces.npy and model_outputs.npy are
    # only consumed inside detect_sequences (detection -> clustering); nothing
    # downstream (rt_sort.pickle, rtsort_fields.mat, extract_rtsort.m) reads
    # them. Each is float16 (num_chans x num_samples) -- the same footprint as
    # the raw recording -- so leaving them accumulates ~2x the raw size per
    # trigger. scaled_traces.npy is kept for now: extract_rtsort.m still needs it
    # to cut waveform snippets/amplitudes, and extractRAW_rtSort.m deletes it
    # once rtsort_results.mat is built.
    for fname in ("model_traces.npy", "model_outputs.npy"):
        fpath = os.path.join(rtsort_dir, fname)
        if os.path.exists(fpath):
            os.remove(fpath)


def _detection_conv(model):
    """The conv submodule RTSort uses as sorter.model for sort_offline. The pickle
    sets sorter.model = None, so it must be re-attached before sorting. Mirrors
    rtSortServer._detection_net (braindance rt_sort.py:460, non-TensorRT path):
    sort_chunk calls self.model(x)[:, 0, :] expecting a 3-D conv output."""
    net = getattr(getattr(model, "model", None), "conv", None)
    if net is None or not callable(net):
        raise RuntimeError("could not resolve detection conv (model.model.conv)")
    return net


def runRTSort_load(file_path, inter_path, pickle_path, window_s=None):
    """LOAD mode: sort the trigger with a PRE-TRAINED sorter instead of detecting a
    new one from the (short) trigger. Unit descriptions (locs / root_elecs / amps /
    latencies / n_before-after) come from the pickle -- e.g. a 30 s-context model --
    while the spike trains come from sort_offline on THIS trigger. Emits the same
    two artifacts extract_rtsort.m consumes: scaled_traces.npy (this trigger, raw
    scaled) + rtsort_fields.mat (pickle descriptions + this trigger's spike trains).
    Mirrors the realtime sidecar's INIT_LOAD + RUN path (rtSortServer.py)."""
    import pickle
    import torch
    rtsort_dir = os.path.join(inter_path, "rtsort")
    os.makedirs(rtsort_dir, exist_ok=True)

    dev = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"[runRTSort] LOAD mode: {pickle_path} (device={dev}, torch {torch.__version__})", flush=True)

    # Re-attach the detection conv the pickle dropped (sorter.model = None on load).
    model = ModelSpikeSorter.load_neuropixels()
    with open(pickle_path, "rb") as fh:
        sorter = pickle.load(fh)
    sorter.model = _detection_conv(model).to(getattr(sorter, "device", dev))
    print(f"[runRTSort] loaded sorter: {int(getattr(sorter, 'num_seqs', -1))} sequences", flush=True)

    # This trigger's recording + segment.
    folder = os.path.dirname(os.path.abspath(file_path))
    recording = read_spikeglx(folder, stream_id="imec0.ap")
    recording = _select_trigger(recording, file_path)
    fs = recording.get_sampling_frequency()
    n_total = recording.get_total_samples()
    n_use = n_total if window_s is None else min(int(round(window_s * fs)), n_total)

    # Scaled AP traces (uV), (n_samp, n_chan) -- the same raw scaled content
    # detect_sequences writes as scaled_traces.npy, used only to cut waveforms.
    traces = np.ascontiguousarray(
        recording.get_traces(start_frame=0, end_frame=n_use, return_scaled=True))

    # Sort with the pre-trained sorter. sort_offline takes (n_chan, n_samp) and
    # returns a (num_seqs,) array of per-sequence spike times in MS. reset=True
    # keeps this trigger independent; inter_path=None -> no persistent files.
    spike_trains = sorter.sort_offline(traces.T, inter_path=None, reset=True, verbose=False)
    n_spk = int(sum(np.asarray(st).size for st in spike_trains))
    print(f"[runRTSort] sort_offline -> {n_spk} spikes over {len(spike_trains)} sequences", flush=True)

    # scaled_traces.npy: (n_chan, n_samp) float16, C-order -- the layout
    # extract_rtsort.m's openNPY_map expects (shape = (chans, samples)).
    np.save(os.path.join(rtsort_dir, "scaled_traces.npy"),
            np.ascontiguousarray(traces.T, dtype=np.float16))

    # rtsort_fields.mat: pickle's unit descriptions + this trigger's spike trains.
    export_fields(rtsort_dir, obj=sorter, spike_trains_override=spike_trains)


if __name__ == "__main__":
    # Optional 3rd arg = detection window in seconds (caps the sort length);
    # omit for the full segment. extractRAW_rtSort.m passes only file_path +
    # inter_path, so the default stays full-length.
    # extractRAW_rtSort.m passes a 300 s (5 min) cap as the 3rd arg to bound the
    # sort length on long recordings; omit it to sort the full segment.
    # Optional 4th arg = a pre-trained rt_sort.pickle path -> LOAD mode (sort the
    # trigger with that sorter). Missing/not-found/failed -> DETECT mode fallback.
    win_s = float(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else None
    pickle_path = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None
    if pickle_path and os.path.isfile(pickle_path):
        try:
            runRTSort_load(sys.argv[1], sys.argv[2], pickle_path, window_s=win_s)
        except Exception as e:  # noqa: BLE001 — LOAD is best-effort; detect is the safety net
            import traceback
            traceback.print_exc()
            print(f"[runRTSort] LOAD mode failed ({e}); falling back to detect_sequences", flush=True)
            runRTSort(sys.argv[1], sys.argv[2], window_s=win_s)
    else:
        if pickle_path:
            print(f"[runRTSort] sorter pickle not found ({pickle_path}); detecting", flush=True)
        runRTSort(sys.argv[1], sys.argv[2], window_s=win_s)
    print("RTSORT_DONE")
