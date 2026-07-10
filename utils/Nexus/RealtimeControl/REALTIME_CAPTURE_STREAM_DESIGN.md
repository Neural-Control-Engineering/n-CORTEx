# Real-time Capture / DataStream — Design Ledger

_Working design for the SLRT→npxls→nexus relay that captures SpikeGLX data ad-hoc
into a Nexus DTS, built so the same machinery also drives continuous
closed-loop streaming back to the speedgoat/SLRT over the axon bus._

Status: **Phases 1–2 running on hardware.** Sidecar builds a sorter (RT-Sort, ~45
seqs on 5 s), per-trial `sort_offline` sorts the captured AP window, LFP+SPK DFs
write to the nexon DTS. Phase 3 (streaming closed loop) DEFERRED: plan stowed below.
Next: confirm the DTS rows + render LFP/SPK with existing Nexus panels.

### Bring-up fixes applied (this session)
- **Sidecar model re-attach** (`rtSortServer.py _attach_model`/`_detection_net`):
  pickling sets `RTSort.model = None`; re-attach `MODEL.model.conv` (rt_sort.py:460,
  the non-TensorRT conv) on the sorter's device so `sort_offline`/`running_sort`
  work. `MODEL.model` (full DetectionModel) returns 2-D → "too many indices".
- **Empty-DTS write** (`dtsIO_writeDF`): guard the `h5_path` probe with `istable`
  so a fresh in-memory nexon (`DTS = []`) flows to the new-row path.
- **Port hygiene** (`rtSortServer.py`): `SO_EXCLUSIVEADDRUSE` + bind-fail exit
  (was `SO_REUSEADDR`, which let stale sidecars co-bind and hijack connections on
  Windows). `proxy_npxls.rtSortLaunch` now attaches-before-spawn (`rtSortConnect`).
- **Stream-stall guard** (`accumulateAP`): errors if imec stops advancing (was an
  infinite drain loop when SpikeGLX isn't acquiring).
- **Debuggability** (`rtSortLaunch`): visible `cmd /k` console + `rtSortAutoLaunch`
  flag to attach to a manually-run sidecar.
- **Proxy socket teardown** (`closeProxies`): was `srv = proxObj.Server; clear("srv")`
  — a no-op on a handle (clears the local ref, never runs the `tcpserver`
  destructor), so the ncortex/slrt listen sockets (8002/8001) were never released
  and reopening `cortex("target")` hit `WSAEADDRINUSE`. Now `delete(proxObj.Server)`,
  guarded by `isa(proxObj.Server,"tcpserver")` so it skips `proxy_npxls.Server`
  (a `SpikeGL` handle, not a tcpserver — a blanket `delete` misdispatches to the
  filesystem `delete` → "Name must be a text scalar").

### Known open items
- **Wire `proxon.nexon`** to a live Nexon before capture (`nCORTEx.proxon.nexon =
  nexon`) — it is not auto-populated unless `nexusCtrl_startNexus` ran. Storage
  fails silently-ish (`no nexon bound`) otherwise.
- Per-spike **amps = 0** (real-time RT-Sort limit) → `amp` measure + `spk_probe`
  zero; recover by cutting root-channel peaks from the AP window (deferred).
- SpikeGLX command link occasionally warns "Connection closed by peer"
  (`ChkConn` recovers) — watch if it worsens.
- INIT_DETECT still uses NumpyRecording + hand-built NP1.0 probe (worked on
  hardware; GEOM override still deferred).
- **Orphaned listen socket on unclean MATLAB exit** → `WSAEADDRINUSE` at
  `proxy_slrt`/`proxy_ncortex` construction that *survives a MATLAB restart* (only a
  reboot clears it). Root cause: `system('start ... cmd /k ...')` in `rtSortLaunch`
  spawns children with `bInheritHandles=TRUE`, so they inherit the open `tcpserver`
  listen sockets (8001/8002); if MATLAB is then killed/crashes (no destructors), the
  inherited copy keeps the port bound after MATLAB dies. Confirmed once via a dead
  PID still owning `169.254.126.16:8001` in `Listen` two days on. The `closeProxies`
  fix above covers *clean* exits; the inheritance path is not yet fixed.
  - Non-reboot clear: bounce the bound NIC — `Disable-NetAdapter -Name "Ethernet"`
    then `Enable-NetAdapter` (admin); the socket is bound to that specific local IP,
    so dropping the address tears down the orphaned TCB. Verify the link-local IP
    returns as `MAC_slrt` after re-enable.
  - Deferred root fix: launch the sidecar without handle inheritance (e.g. .NET
    `Process.Start` w/ `UseShellExecute=true` instead of MATLAB `system`), and/or
    track+kill spawned sidecar PIDs on close.

---

## Relay path

```
SLRT host --tcp(axon)--> proxy_slrt.relayTransmission --(ctrlKey.getCmd)-->
  proxy_slrt.<cmd>(pyd,sze) --> relayToTargetProxies -->
    proxy_npxls.<cmd>(pyd,sze)  [SpikeGL Fetch, js=2 imec]
      --> PROCESS (LFP DF from LF band / RTSort SPK from AP band)
      --> SINK
```

## Shared core — ACQUIRE / PROCESS / SINK

Capture and DataStream differ **only** in the sink. Keep the acquire+process
stages identical and swap the sink so both command families reuse one pipeline.

| Stage | Capture (`start/stopCapture`) | DataStream (`start/stopDataStream`) |
|-------|-------------------------------|-------------------------------------|
| ACQUIRE | bracket + single `Fetch`, or drain-loop for long windows | continuous drain-loop |
| PROCESS | LFP DF, RTSort SPK DF (batch) | feature/decoder output (per-chunk) |
| SINK | `proxon.nexon` DTS (`storeToDTS`), terminal at stop | `ctxCtrl_TX` axon back to speedgoat, per-chunk |

**Rule:** any new capture machinery must be written sink-agnostic (mode flag or
sink callback) so `start/stopDataStream` inherits it for free.

---

## Decisions

**A. RTSort process model.** `startNexus` provides a warm *in-process* nexus-env
Python (fine for Nexus analysis `py.*`). The RTSort stack (`torch/c10.dll`,
`pyexpat`→`libexpat.dll`) collides with MATLAB's resident DLLs in-process on
Windows (see `Extraction/.../KILOSORT_RTSORT_SUBPROCESS.md`). Default plan: a
**persistent RTSort sidecar** (separate nexus-env process, model loaded once,
warm). *Pivotal test before committing:* in the live host session try
`py.importlib.import_module('torch')` — if it imports clean on the host, run
RTSort in-process and drop the socket; the PROCESS stage is identical either way.

**B. Long captures (exceed ring buffer).** Bracket + single `Fetch` for
trial-scale windows (O(1), lowest latency). For windows that outlive SpikeGLX's
stream ring buffer, drain-loop: each tick fetch *available* samples
(`GetStreamSampleCount - lastHead`), append to `captureBuffer`, advance pointer
using the `headCt` returned by `Fetch` (authoritative — no self-counter).
Cadence must keep the buffer near-empty (`T·Fs < buffer_depth` with margin).

**C. Streaming feedback (closed-loop to speedgoat).** `start/stopDataStream`
(already `ctrlKey` 1/2) reuse the shared core with SINK = outbound axon TX.
Vehicle: `axon_build("stream")` (per-target `SZE`/`PYD`) serialized by the
existing `ctxCtrl_TX`/`ctxCtrl_serialize`. TODO: outbound stream-TX method on
`proxy_slrt` + matching RX block in the speedgoat Simulink model. Feedback
payload is low-D (a control/decoder signal), which is why the stream axon is
small. Latency note: per-window `detect_sequences` = pseudo-realtime; true
closed-loop wants RTSort `running_sort` streaming mode (Phase 3) — the sink
abstraction avoids a rearchitect to get there.

**D. AP→sidecar handoff.** Raw `int16` array over socket (lowest latency, fewest
I/O exchanges). Sidecar wraps the array as an in-memory NumpyRecording (NP1.0
geometry built server-side; GEOM override deferred).

**E. Two-phase RT-Sort — build once, run per trial (in memory).** RT-Sort has two
phases and they must NOT be conflated:
- `detect_sequences` = **builds** the sorter (discovers sequences). Heavy
  (~1 hr/10 min replay), writes `scaled_traces`/`model_*` to disk. Run **once**
  per session.
- `running_sort` = **uses** the built sorter to sort new data. Light, streams
  `buffer_size` chunks **in memory, no disk**. This is the per-trial path.

**Build once** (two triggers, both populate the same warm sorter + cached static
fields):
1. `detectSequences(durSec)` — drain a training window from the live ring buffer
   (async, non-destructive), send to sidecar → `detect_sequences` → warm RTSort
   object; MATLAB runs `extract_rtsort`+`loadRTSort_spk` **once** → `spkStatic`.
2. `loadSorter(dir)` — sidecar loads `rt_sort.pickle` (for `running_sort`);
   MATLAB loads sibling `rtsort_results.mat` → `spkStatic`.

**Run per trial:** `apMat` → `running_sort` → dynamic spikes
(`spike_times_s`/`clusters`/`amplitudes`) over socket, in memory. Merge with
cached `spkStatic` (templates/spatial/locs/root_elecs/quality — fixed by the
sequences) → `formatSpk_toDTS` → RTS_ DFs. **Zero per-trial disk, zero
re-detection.** This is also the Phase 3 closed-loop primitive.

> `formatSpk_toDTS` inputs split naturally: STATIC (per-sequence, cached once) vs
> DYNAMIC (per-trial spikes). Only the dynamic three fields change per trial.

**Open:** exact braindance `running_sort` signature (buffer in / detections out)
must be confirmed against the installed env — `_sort_window()` in `rtSortServer.py`
is the single adapter point.

---

## DTS addressing

`DF.dtsIdx = struct('session_label', ..., 'trial_num', ...)` →
`dtsIO_writeDF`→`nex_searchRowAddress` matches or appends the per-trial row,
mirroring offline `extLFP`/`extSPK`. Sources at capture time:
`session_label = nCORTEx.params.sessionLabel`; `trial_num` from the command
payload (`pyd`).

## Data schema (match offline, built ad-hoc)

- **LFP DF:** `{.df (chan×t), .ax.t, .ax.chans}` — LF band decimated to true LF Fs
  (do **not** ship 30 kHz "LFP"; `js=2` serves LF at the AP rate, sample-held).
- **SPK DFs:** `loadRTSort_spk` schema → `formatSpk_toDTS` → 5 prefixed DFs
  (`RTS_spk_activity_df` etc.). See `Extraction/.../extSPK.m`.

---

## Known wiring fixes (fold into Phase 1)

- `proxObj.proxon.proxObjs.nexus_1` is stale — no `proxObjs` field. Route via
  `proxObj.proxon.nexon` (populated by `nexusCtrl_startNexus`).
- `proxy_npxls.readData` references undefined `windowLen`.

## Phases

1. **Relay + capture + LFP DF + DTS write** (no Python). Sink-agnostic core. ✅ **DONE**
   - `proxy_slrt.startCapture/stopCapture` → `relayToTargetProxies` (ctrlKey 3/4;
     replaced the old no-`pyd` `startCapture` that read target bytes off the socket).
   - `proxy_npxls.startCapture` (mark ring-buffer head − pre-buffer),
     `stopCapture` (single `Fetch`, slice AP/LF/SY, LFP DF, DTS write),
     `storeToDTS` (sink via `proxon.nexon`), capture-state fields, `readData`
     `windowLen`→`streamWindowLen`.
   - `npxls/npxlsCapture_toLFP.m` — LF band → boxcar-decimated flat LFP DF
     (`lfp_df`/`lfp_t`/`lfp_chans`).
   - SPK left as a seam (commented `buildSPK_DF`) — no empty columns written.
   - **Drain-loop:** ✅ `drainCapture` + `capTimer` (fires only for long captures;
     short ones reduce to one Fetch = the bracket). `capReadHead` advances by the
     Fetch-returned `headCt`.
   - **Dead stub noted:** `proxy_slrt.endCapture` (old protocol, superseded by
     `stopCapture`) left in place — remove when convenient.
2. **RTSort sidecar** — ✅ **built (untested on hardware).** Build-once/run-per-trial:
   - `rtSortServer.py` — persistent nexus-env server: warm model + warm sorter;
     INIT_DETECT / INIT_LOAD / RUN / QUIT over a little-endian socket.
   - `proxy_npxls`: `detectSequences` (drain training window → sidecar → cache
     `spkStatic`), `loadSorter` (pickle + results.mat), `buildSPK_DF`
     (running_sort → merge static → `formatSpk_toDTS`), transport methods.
   - `npxls/npxlsCapture_writeSPK.m` — 5 RTS_ DFs + quality, flat schema.
   - **API confirmed (nexus env):** `sort_offline(array (nchan,nsamp),
     inter_path=None, reset=True)` → `(num_seqs,)` of ms spike-time lists. RUN
     path passes a raw array (no NumpyRecording/probe). `running_sort(obs)` →
     list of `(seq_id, time_ms)` is the Phase 3 streaming entry.
   - **Inherent limit:** neither `sort_offline` nor `running_sort` returns
     amplitudes → per-spike `amps=0` in the RUN path (so the `amp` measure and
     `spk_probe` DF are zero). Recoverable by cutting root-channel peaks from the
     AP window at each spike frame — future enhancement, traces already in hand.
   - **Remaining test-risk:** NumpyRecording + manual NP1.0 probe accepted by
     `detect_sequences` in the INIT_DETECT (build) path only — the per-trial RUN
     path no longer depends on it.
3. **start/stopDataStream (continuous closed loop)** — ⏸️ **DEFERRED to a future
   session** (design locked; see "Phase 3 — deferred plan" below). Only scaffolding
   landed: `proxon.primaryProxy(id)` (lets a target proxy reach an orchestrator
   proxy — npxls→slrt for TX). Current focus is bring-up/testing of Phases 1–2 +
   the speedgoat side (see "Bring-up & Testing").

---

## Bring-up & Testing (current focus)

Goal: **capture a Neuropixels LFP + SPK for one trial and render it with existing
Nexus libraries.** Two independent tracks; get A green first (no Simulink needed),
then B drives A end-to-end.

### Track A — neural capture → DTS → render (no speedgoat)
Bypass the SLRT relay; call the npxls proxy methods directly in MATLAB. This
isolates the hard part (capture → DF → DTS → render) from the wire protocol.

Prereqs: SpikeGLX running + streaming a probe (real or sim); `startNexus` run so
`proxon.nexon` is populated; `proxObj = proxy_npxls(<sglIP>, nCORTEx)` constructed
and attached to a `proxon` (so `proxObj.proxon.nexon` resolves).

1. **Sorter build** — `proxObj.detectSequences(60)` (or `proxObj.loadSorter(dir)`).
   Verify: sidecar launches (model loads once), `spkStatic` caches N units, no
   INIT_DETECT probe error. ← first place NumpyRecording+NP1.0 probe is exercised.
2. **Capture** — `proxObj.startCapture(uint8(1))`; wait a few s; `proxObj.stopCapture([])`.
   Verify: no `capOverrun` warning; `nexon.console.BASE.DTS` gains a row addressed
   `(sessionLabel = nCORTEx.params.sessionLabel, trialNumber = 1)` with columns
   `lfp_df/lfp_t/lfp_chans` and `RTS_spk_*` (+ `RTS_spk_units_quality`).
3. **Sanity-check DFs** — `grabDF`/`dtsIO_composeDF` the `lfp` and `RTS_spk_activity`
   DFs; confirm `lfp_df` is chans×time at ~`lfTargetFs`, `RTS_spk_activity` is
   unit×t×measure with a non-empty `raster`/`rate` (amp will be 0 — expected).
4. **Render** — LFP via the existing LFP timecourse/`visEXT_LFP`-equivalent; SPK via
   the raster/rate from `RTS_spk_activity` (same schema as offline `extSPK`, so the
   existing Nexus panels/plots apply). `updateControlPanel` already fired on write.

First-run watch list (from Phase 2 notes): imec column order `[AP,LF,SY]`;
NumpyRecording+probe accepted by `detect_sequences`; `sort_offline` array
orientation `(nchan,nsamp)`.

### Track B — speedgoat axon TX/RX (.slx side)
Get the speedgoat to trigger the capture over the full-duplex axon TCP link so
Track A runs end-to-end.

**Command frame the speedgoat must SEND** (to `proxy_slrt.Server`; decoded by
`ctxCtrl_RX` in `relayTransmission`): the serialized command axon — build it
exactly as MATLAB does and send the bytes:
```matlab
[~, ax] = axon_build("command");
ax.CMD(ctrlKey.startCapture) = 1;      % =3 ; use ctrlKey.stopCapture (=4) to end
ax.PYD(ctrlKey.startCapture, 1) = trialNum;   % trial number (uint8, 1..255)
tx = ctxCtrl_TX(ax);                   % 294 bytes = CMD(21) + SZE(63) + PYD(210)
```
Frame is fixed 294 B (N=21 ctrlKey members × {1 CMD, 3 SZE, 10 PYD}). In the
Simulink model, replicate with the axon bus (`dictionary_axon.sldd`) + a MATLAB
Function block calling `ctxCtrl_TX`, or generate `tx` once and send it. The proxy
server callback triggers at `numBytes_cmd` (=21) bytes then reads all available —
send the whole 294-B frame in one write.

**ACK the speedgoat will RECEIVE** (`proxy_slrt.returnCommand` → `ctxCtrl_TX`): a
294-B frame with `CMD[sel]=1` for the commands it just ran. Build the RX to read
294-B frames and confirm the echoed CMD bit.

**Isolation test before wiring the model:** point a plain `tcpclient` (or a tiny
SLRT harness) at `proxy_slrt.Server` and send the 294-B `tx` above → should fan
out to `proxy_npxls.startCapture`. This validates the wire path without the .slx.

> Streaming feedback TX (`streamTX`, `'S'`-tagged frame) is Phase 3 — not needed
> for the capture-and-render goal.

---

## Phase 3 — deferred plan (design locked, not built)

Continuous closed loop: `running_sort` streaming, sink = axon TX back to the
speedgoat. Same ACQUIRE/PROCESS/SINK core as capture, sink swapped.

**Ownership:** `proxy_npxls` owns the loop (drain + sidecar); `proxy_slrt` owns the
speedgoat link and does the TX. npxls reaches slrt via `proxon.primaryProxy("slrt")`
(already added).

**To build:**
- `proxy_slrt`: `startDataStream`/`stopDataStream` relay shims (ctrlKey 1/2; replace
  the empty `startDataStream` stub) + `streamTX(feature)` — the outbound
  measure-agnostic frame (SZE describes dims/dtype, PYD carries bytes; population
  rate first, SSM/LDA/CEBRA manifold metrics later). Write to `proxObj.Server`
  (same full-duplex socket, `'S'`-tagged to disambiguate from command ACKs).
- `proxy_npxls`: `startDataStream` (query Fs/nAP/nUnits, mark `streamReadHead`,
  `rtSortStreamStart`, arm `streamTimer`), `streamTick` (drain new AP frames →
  `STREAM_CHUNK` → `running_sort` spikes → `streamReducer` → `slrt.streamTX`),
  `stopDataStream` (stop timer, `STREAM_STOP`). Fields: `streamTimer`,
  `streamPeriod`(~0.05), `streamReducer` (fn handle, default population rate),
  `streamFs`, `streamNAP`, `streamNUnits`, `streamReadHead`.
- `npxls/npxlsStreamReducer_popRate.m` — default reducer (spikes → Hz); swappable
  seam for manifold decoders (the "built-in + pluggable" choice).
- `rtSortServer.py`: `START_STREAM` (6, `sorter.reset()`), `STREAM_CHUNK` (7,
  `running_sort(obs (nframes,nchan))` → `(seq_id,time_ms)` reply
  `[u32 n][i32 seq*n][f64 tms*n]`), `STOP_STREAM` (8). Note: `running_sort` wants
  `(num_frames, num_electrodes)` = obs as-received (NO transpose, unlike
  `sort_offline`).
- Speedgoat: RX block for the `'S'` stream frame → into control-theory blockset.

**Latency:** localhost per-chunk hop is sub-ms; cost is `running_sort` inference
per chunk (small). This is the genuine low-latency path vs per-trial `sort_offline`.
