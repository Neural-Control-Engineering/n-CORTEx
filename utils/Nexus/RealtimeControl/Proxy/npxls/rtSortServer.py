# Persistent RT-Sort sidecar for real-time capture (Phase 2).
#
# Loads the detection model ONCE and keeps a warm RTSort *sorter* resident, so the
# proxy_npxls capture path can sort each trial with running_sort IN MEMORY (no
# per-trial disk, no re-detection). Runs in the nexus conda env as a SEPARATE
# PROCESS (never embedded in MATLAB) to dodge the libexpat.dll in-process
# collision documented in Extraction/.../KILOSORT_RTSORT_SUBPROCESS.md.
#
# Two-phase design (see RealtimeControl/REALTIME_CAPTURE_STREAM_DESIGN.md, E):
#   build once  : INIT_DETECT (detect_sequences on a training window) or
#                 INIT_LOAD (unpickle a pre-built rt_sort.pickle)  -> warm sorter
#   run per trial: RUN (running_sort/sort_offline on the AP window) -> spikes
#
# Wire protocol (little-endian, one client):
#   in  INIT_DETECT [u8 1][u32 nsamp][u32 nchan][f64 fs][int16 traces C-order]
#   in  INIT_LOAD   [u8 2][u32 len][utf8 pickle_path]
#   in  RUN         [u8 3][u32 nsamp][u32 nchan][f64 fs][int16 traces C-order]
#   in  QUIT        [u8 5]
#   out OK          [u8 3][u32 len][payload]      (INIT_DETECT: utf8 session dir;
#                                                  INIT_LOAD: empty;
#                                                  RUN: [u32 n][f64 t*n][i32 c*n][f64 a*n])
#   out ERR         [u8 4][u32 len][utf8 message]
#
# argv: rtSortServer.py <port> <npxls_dir> <work_dir>
#   npxls_dir : dir containing runRTSort.py (reused for export_fields + probe patch)
#   work_dir  : root for per-detect output dirs (rt_sort.pickle, scaled_traces.npy,
#               rtsort_fields.mat) that extract_rtsort.m then consumes.
import os
import sys
import time
import socket
import struct
import pickle
import numpy as np

# ---- detection params (kept identical to runRTSort.py) ----
_DETECT_KW = dict(
    return_spikes=True,
    stringent_thresh=0.175,
    loose_thresh=0.075,
    inference_scaling_numerator=15.4,
    min_amp_dist_p=0.1,
    max_latency_diff_spikes=2.5,
    max_amp_median_diff_spikes=0.45,
    max_amp_median_diff_sequences=0.45,
    max_root_amp_median_std_sequences=2.5,
)

# module-level warm state
MODEL = None
SORTER = None
runRTSort = None  # the reused module (export_fields + probe monkeypatch)


def log(msg):
    print(f"[rtSortServer] {msg}", flush=True)


def _detection_net(mss):
    """Return the conv submodule RTSort uses as self.model. sort_chunk calls
    self.model(x)[:, 0, :] expecting a 3-D conv output; braindance sets this to
    model.model.conv (rt_sort.py:460 — the non-TensorRT path). MODEL.model (the
    full DetectionModel) returns 2-D, which is the 'too many indices' error."""
    net = getattr(getattr(mss, "model", None), "conv", None)
    if net is None or not callable(net):
        raise RuntimeError("could not resolve MODEL.model.conv (detection conv)")
    return net


def _attach_model(sorter):
    """Re-attach the detection conv so sort_offline/running_sort work on a
    reloaded sorter (pickle sets sorter.model = None)."""
    net = _detection_net(MODEL)
    dev = getattr(sorter, "device", "cuda")
    sorter.model = net.to(dev)
    log(f"re-attached detection net: {type(net).__name__} on {dev}")


def recvall(conn, n):
    buf = bytearray()
    while len(buf) < n:
        chunk = conn.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("socket closed mid-message")
        buf.extend(chunk)
    return bytes(buf)


def send_frame(conn, mtype, payload=b""):
    conn.sendall(struct.pack("<BI", mtype, len(payload)) + payload)


def recv_window(conn):
    """Read a [u32 nsamp][u32 nchan][f64 fs][int16 traces] window -> (traces, fs).
    traces is C-order (nsamp, nchan)."""
    nsamp, nchan = struct.unpack("<II", recvall(conn, 8))
    (fs,) = struct.unpack("<d", recvall(conn, 8))
    raw = recvall(conn, nsamp * nchan * 2)
    traces = np.frombuffer(raw, dtype="<i2").reshape(nsamp, nchan)
    return np.ascontiguousarray(traces), fs


def build_np1_probe(nchan):
    """Neuropixels 1.0 default geometry (Kilosort chanMap): 4 x-positions
    repeating, 20 um vertical pitch, 2 sites/row. NP1.0-specific; a GEOM override
    from MATLAB (GetGeomMap) can replace this for other probes (future work)."""
    import probeinterface as pi
    xpat = np.array([43.0, 11.0, 59.0, 27.0])
    pos = np.zeros((nchan, 2))
    pos[:, 0] = xpat[np.arange(nchan) % 4]
    pos[:, 1] = 20.0 * (np.arange(nchan) // 2)
    probe = pi.Probe(ndim=2)
    probe.set_contacts(positions=pos, shapes="square", shape_params={"width": 12})
    probe.set_device_channel_indices(np.arange(nchan))
    return probe


def make_recording(traces, fs):
    """Wrap an in-memory AP window as a probe-attached NumpyRecording. Gains/offsets
    are set so get_traces(return_scaled=True) works (detect/sort need scaled traces);
    absolute uV scaling is not critical — inference_scaling_numerator handles it."""
    from spikeinterface.core import NumpyRecording
    rec = NumpyRecording(traces_list=[traces], sampling_frequency=float(fs))
    rec = rec.set_probe(build_np1_probe(traces.shape[1]))
    rec.set_channel_gains(1.0)
    rec.set_channel_offsets(0.0)
    return rec


def handle_init_detect(conn, work_dir):
    global SORTER
    from braindance.core.spikesorter.rt_sort import detect_sequences
    traces, fs = recv_window(conn)
    out_dir = os.path.join(work_dir, f"detect_{int(time.time()*1000)}")
    os.makedirs(out_dir, exist_ok=True)
    rec = make_recording(traces, fs)
    dur_ms = traces.shape[0] / rec.get_sampling_frequency() * 1000.0
    detect_sequences(rec, out_dir, MODEL,
                     recording_window_ms=(0, float(np.floor(dur_ms))),
                     **_DETECT_KW)
    runRTSort.export_fields(out_dir)
    # drop the bulk detection intermediates MATLAB never reads (mirror runRTSort.py);
    # scaled_traces.npy stays — extract_rtsort.m cuts waveforms/amps from it.
    for f in ("model_traces.npy", "model_outputs.npy"):
        p = os.path.join(out_dir, f)
        if os.path.exists(p):
            os.remove(p)
    # warm the sorter for running_sort from the pickle we just wrote
    with open(os.path.join(out_dir, "rt_sort.pickle"), "rb") as fh:
        SORTER = pickle.load(fh)
    _attach_model(SORTER)
    log(f"detect -> {out_dir} ({int(getattr(SORTER, 'num_seqs', -1))} seqs)")
    send_frame(conn, 3, out_dir.encode())


def handle_init_load(conn):
    global SORTER
    (nlen,) = struct.unpack("<I", recvall(conn, 4))
    pickle_path = recvall(conn, nlen).decode("utf-8")
    with open(pickle_path, "rb") as fh:
        SORTER = pickle.load(fh)
    _attach_model(SORTER)
    log(f"loaded sorter from {pickle_path} ({int(getattr(SORTER, 'num_seqs', -1))} seqs)")
    send_frame(conn, 3, b"")


def _sort_window(sorter, ap_c_by_s):
    """Sort one AP window with the already-built `sorter` and return three
    equal-length arrays: spike times (s, window-relative), 1-indexed cluster ids
    (matching loadRTSort_spk unit_ids), and per-spike amplitudes.

    Confirmed against braindance RTSort.sort_offline (nexus env): it accepts a raw
    (n_channels, n_samples) array directly (no recording/probe needed — the built
    sequences encode their channels), and returns a (num_seqs,) array whose u-th
    element is that sequence's spike times in MS. reset=True makes each trial
    independent. inter_path=None -> no persistent scaled_traces written.

    Amps: neither sort_offline nor running_sort exposes per-spike amplitude
    (real-time RT-Sort emits time + sequence only), so amps are 0 here. To recover
    them, cut the root-channel peak from `ap_c_by_s` at each spike frame (a future
    enhancement — the traces are already in hand)."""
    result = sorter.sort_offline(ap_c_by_s, inter_path=None, reset=True, verbose=False)
    times, clusters, amps = [], [], []
    for u, st in enumerate(result):
        st = np.asarray(st, dtype=np.float64).ravel()
        if st.size == 0:
            continue
        times.append(st / 1000.0)                 # ms -> s
        clusters.append(np.full(st.shape, u + 1, dtype=np.int32))   # 1-indexed
        amps.append(np.zeros(st.shape, dtype=np.float64))
    if times:
        return (np.concatenate(times), np.concatenate(clusters), np.concatenate(amps))
    return (np.zeros(0), np.zeros(0, dtype=np.int32), np.zeros(0))


def handle_run(conn):
    if SORTER is None:
        raise RuntimeError("no sorter built/loaded (INIT_DETECT or INIT_LOAD first)")
    traces, fs = recv_window(conn)                 # traces (nsamp, nchan)
    times, clusters, amps = _sort_window(SORTER, traces.T)   # -> (nchan, nsamp)
    n = int(times.size)
    payload = (struct.pack("<I", n)
               + times.astype("<f8").tobytes()
               + clusters.astype("<i4").tobytes()
               + amps.astype("<f8").tobytes())
    send_frame(conn, 3, payload)
    log(f"run -> {n} spikes")


def serve(conn, work_dir):
    handlers = {1: lambda c: handle_init_detect(c, work_dir),
                2: handle_init_load,
                3: handle_run}
    while True:
        hdr = conn.recv(1)
        if not hdr:
            raise ConnectionError("client closed")
        mtype = hdr[0]
        if mtype == 5:          # QUIT
            log("quit requested")
            return True
        h = handlers.get(mtype)
        if h is None:
            send_frame(conn, 4, f"unknown msg type {mtype}".encode())
            continue
        try:
            h(conn)
        except Exception as e:  # noqa: BLE001 — report to client, keep serving
            import traceback
            traceback.print_exc()
            send_frame(conn, 4, str(e).encode())


def main():
    global MODEL, runRTSort
    port = int(sys.argv[1])
    npxls_dir = sys.argv[2]
    work_dir = sys.argv[3]
    os.makedirs(work_dir, exist_ok=True)

    # bind+listen FIRST so the MATLAB client connects immediately; the slow model
    # load happens after, and the first request simply waits on it.
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    # NOT SO_REUSEADDR: on Windows it lets a second process co-bind the same port
    # and silently hijack connections (stale sidecars stealing requests during
    # bring-up). SO_EXCLUSIVEADDRUSE forbids co-binding, so a duplicate sidecar
    # fails the bind loudly instead.
    if hasattr(socket, "SO_EXCLUSIVEADDRUSE"):
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
    try:
        srv.bind(("127.0.0.1", port))
    except OSError as e:
        log(f"FATAL: cannot bind 127.0.0.1:{port} — a sidecar is probably already "
            f"running on this port. Kill stray python.exe and relaunch. ({e})")
        sys.exit(1)
    srv.listen(1)
    log(f"listening on 127.0.0.1:{port}; loading model...")

    sys.path.insert(0, npxls_dir)
    import runRTSort as _rr           # applies the pi.read_spikeglx probe monkeypatch on import
    runRTSort = _rr
    from braindance.core.spikesorter.rt_sort import ModelSpikeSorter
    import torch
    MODEL = ModelSpikeSorter.load_neuropixels()
    log(f"model loaded (device={'cuda' if torch.cuda.is_available() else 'cpu'}); ready")

    while True:
        conn, addr = srv.accept()
        log(f"client connected: {addr}")
        try:
            if serve(conn, work_dir):
                break               # QUIT -> shut the server down
        except (ConnectionError, OSError):
            log("client disconnected; awaiting reconnect")
        finally:
            conn.close()
    srv.close()


if __name__ == "__main__":
    main()
