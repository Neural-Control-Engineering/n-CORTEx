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

_TRIG_RE = re.compile(r"_t(\d+)\.imec\d*\.ap\.bin$")


def _to_numpy(x):
    """torch tensor / list / array -> float64 numpy array."""
    if hasattr(x, "detach"):
        x = x.detach().cpu().numpy()
    return np.asarray(x, dtype=np.float64)


def _select_trigger(recording, bin_path):
    """Select only the trigger named in bin_path (e.g. _t0) without touching the
    raw .bin. SpikeGLX triggers become segments in ascending trigger order."""
    if recording.get_num_segments() == 1:
        return recording
    m = _TRIG_RE.search(os.path.basename(bin_path))
    if m is None:
        return recording
    target_t = int(m.group(1))
    folder = os.path.dirname(os.path.abspath(bin_path))
    trigs = sorted({int(mm.group(1)) for f in os.listdir(folder)
                    for mm in [_TRIG_RE.search(f)] if mm})
    if target_t not in trigs:
        raise ValueError(f"Trigger t{target_t} not found among {trigs} in {folder}")
    return recording.select_segments([trigs.index(target_t)])


def export_fields(out_dir):
    """Load rt_sort.pickle and export the fields extract_rtsort.m needs as a
    plain .mat (ragged spike trains become a MATLAB cell via an object array)."""
    import pickle
    pickle_path = os.path.join(out_dir, "rt_sort.pickle")
    with open(pickle_path, "rb") as fh:
        obj = pickle.load(fh)

    spike_trains = np.empty((len(obj.seq_spike_trains),), dtype=object)
    for i, st in enumerate(obj.seq_spike_trains):
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


def runRTSort(file_path, inter_path):
    rtsort_dir = os.path.join(inter_path, "rtsort")
    os.makedirs(rtsort_dir, exist_ok=True)
    detection_model = ModelSpikeSorter.load_neuropixels()
    folder = os.path.dirname(os.path.abspath(file_path))
    recording = read_spikeglx(folder, stream_id="imec0.ap")
    recording = _select_trigger(recording, file_path)
    # Clamp the detection window to the actual segment duration. braindance
    # allocates the on-disk traces buffer from recording_window_ms, but
    # get_traces() clamps to the real length -- if the segment is shorter than
    # the requested window (e.g. an 11 s trigger vs a 60 s window) the buffer is
    # over-sized and _save_traces_si raises "could not broadcast ... into ...".
    # floor() keeps round(end_ms * samp_freq) <= total samples.
    dur_ms = recording.get_total_samples() / recording.get_sampling_frequency() * 1000.0
    window_end_ms = min(1 * 60 * 1000, math.floor(dur_ms))
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


if __name__ == "__main__":
    runRTSort(sys.argv[1], sys.argv[2])
    print("RTSORT_DONE")
