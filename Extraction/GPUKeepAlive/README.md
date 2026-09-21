# GPUKeepAlive

Keeps the RTX 5070 out of deep idle during offline extraction so it doesn't fall
off the PCIe bus (idle bus-drop → display TDR / hard hang).

## Why it's needed

`extractRAW_NPXLS.m` runs the GPU in short per-trigger bursts, each in its own
subprocess that exits when done (`runKilosort4.py`, then `runRTSort.py`). Between
those bursts — and during the CPU/disk phases (LFP filter, sync, save, zip, cloud
copy) — the GPU is fully idle. On this machine the GPU sits in a **chipset (PCH)
PCIe 3.0 x4 slot** (the CPU x16 slot is occupied by the NI DAQ), and during those
idle windows the hardware descends to **P8 / PCIe L1 / Gen1** and drops off the
bus. This is a hardware/slot fragility, **not** a bug in the extraction code — the
subprocesses manage their CUDA contexts cleanly.

## What it does

`gpu_pacifier.py` runs alongside the batch and keeps the GPU awake with:

- **continuous small matmuls** → holds the GPU **core** off P8, and
- **a periodic host↔device transfer** → holds the PCIe **link** in L0 (out of
  L1/Gen1). Link power management responds to bus *transactions*, not GPU compute,
  so the matmul alone is not enough (matmul-only was measured leaving it at
  P8/Gen1; adding the transfer moved it to **P1/Gen3**).

Measured footprint at defaults: ~15% util, ~45 W, ~48 °C. Tune down
(`--size 1024 --iters 5`) if it contends with Kilosort4/RT-Sort; tune up if the
logger still dips to P8.

## How it's wired

`extractRAW_NPXLS.m` starts it before the session loop and stops it via
`onCleanup` (fires on any exit, including error), so its lifetime tracks the
extraction run — no manual start/stop, survives reboots (the next run brings it
up). Duplicate-safe: a second start is a no-op while one is already alive.

## Manual use (nexus env)

```
C:\Users\Primus\miniconda3\envs\nexus\python.EXE gpu_pacifier.py          # start
C:\Users\Primus\miniconda3\envs\nexus\python.EXE gpu_pacifier.py --stop   # stop
```

## Runtime artifacts

PID file and logs live in `C:\Users\Primus\gpu-tdr-diag\` (with the TDR logger's
CSVs), not in the repo. The GPU-TDR-Logger scheduled task there records
pstate/link-gen every 5 s; a clean night shows P1/Gen3 throughout and no
`DEVICE_LOST` rows.

## Note

This is an interim workaround. The durable, zero-watt fix is BIOS-side (disable
PCIe ASPM / L1 substates on the PCH port, force that slot to Gen3) plus NVIDIA
Control Panel → "Prefer maximum performance"; see
`C:\Users\Primus\Downloads\RTX5070_bus-drop_FIX_and_experiment.txt`.

---

## Session log — 2026-09-17 (resume here after reboot)

### What happened today

New failure mode identified: under-load drop during Kilosort, distinct from the
idle P8 drops the pacifier was built to prevent.

**Root cause:** Kilosort power spike (47 W → 169 W) + 5.5 GB VRAM allocation
burst through the PCH x4 link saturated PCH bandwidth, dropping the GPU off the
bus. The pacifier was running fine — this is not an idle drop.

**Why it started on Sept 16 (after 2.5 clean weeks):** The Windows Defender
platform update KB4052623 (installed Sept 15 05:10) made Defender scan the large
SpikeGLX `.bin` files during extraction. The NVMe (WD SN850) and the GPU share
the same PCH x4 link — Defender scanning adds competing PCIe reads at exactly the
moment Kilosort is bulk-allocating VRAM through that same bottleneck.

### Fixes applied today

| Fix | Status | Notes |
|-----|--------|-------|
| `HwSchMode=1` (HAGS disabled) | **NEEDS REBOOT** | Reduces GPU scheduler overhead during Kilosort load spikes |
| Defender path exclusions | **Active now** | `C:\SGL_Data`, `C:\nCORTEx_local`, `D:\nCORTEx_local`, `X:\`, `C:\Users\Primus\miniconda3\envs\nexus` |
| TdrDelay/TdrDdiDelay=60 | Already applied prior | Confirmed in registry |

### Still outstanding (from full checklist)

- **BIOS update** — currently 0820 (2021), predates Blackwell. Highest remaining
  leverage. Flash via ASUS EZ Flash from USB.
- Driver clean reinstall (currently 610.74)

### After reboot — what to verify

```powershell
# Confirm HAGS is off
(Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers").HwSchMode
# → should be 1

# Confirm Defender exclusions survived
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -Command `"(Get-MpPreference).ExclusionPath`"" -Wait

# Check PCIe link under load (run a short Kilosort job, then)
nvidia-smi --query-gpu=pcie.link.gen.current,pcie.link.width.current --format=csv
# → Gen3, 4  (x4 is the slot limit; Gen3 not Gen1 = link is healthy)
```

Full history and checklist: `C:\Users\Primus\gpu-tdr-diag\RTX5070_bus-drop_fix_checklist.txt`

---

## Why pcie_monitor.py failed to prevent the 2026-09-17 drop

Three nested failures, confirmed against `pcie_log_20260917_183846.csv` and
`pcie_log_20260917_182959.csv`.

### 1. Sampling rate mismatch — the burst was physically invisible

`nvmlDeviceGetPcieThroughput` reports the last **20 ms** of traffic.
`pcie_monitor.py` polls it every **1 s** — it sees 2% of time.

The fatal VRAM allocation (+1168 MiB, ~330 ms at PCIe 3.0 x4 max) completed
entirely inside one 1 s gap. Direct evidence from the CSV:

```
19:10:48  vram=1331 MiB  gpu_rx=519 MB/s
19:11:48  vram=2499 MiB  gpu_rx=2 MB/s    ← +1168 MiB landed; burst already gone
```

The monitor observed nothing. Controller state: CLEAR throughout.

### 2. Threshold calibrated for the wrong Kilosort profile

The earlier session (`pcie_log_20260917_182959.csv`) ran a **large** Kilosort
job (4156 MiB VRAM, 76–80 W sustained). That produced continuous gpu_rx of
200–640+ MB/s for several minutes, and the old code (single-sample trigger,
lower threshold ≈700 MB/s) correctly went ACTIVE at 18:32:46 and suspended
robocopy.

The threshold was then **raised to 900 MB/s** to stop triggering on the
pacifier's observed max (708 MB/s). The fatal second Kilosort run was
**smaller** (2499 MiB VRAM, 41–53 W). Its max observed gpu_rx was **443 MB/s**
in any sample — never close to 900. The threshold was calibrated against the
large run's bandwidth profile; the small run was a different workload.

### 3. `trigger_secs=2` compounded the problem

The 2-consecutive-sample requirement was added to filter single-sample
pacifier bursts. For a 330 ms burst that's already invisible to one 1 s
sample, requiring two is academic — but it also means any borderline signal
that does get caught once is silently discarded.

### Near-term mitigation

Going to **serialize**: run robocopy only when extractRAW_NPXLS is idle.
No concurrent GPU load + disk I/O through the shared PCH link.

### Paths to a real fix (when bandwidth allows)

- **VRAM-delta trigger**: `vram_used` is a stable counter, not a rate window.
  `Δvram > 200 MiB in one sample` is an unambiguous Kilosort-start signal
  that doesn't miss sub-second bursts. Doesn't require faster polling.
- **100 ms polling**: still misses ~70% of a 330 ms burst but much better
  odds. Check win32pdh/psutil overhead at 10 Hz first.
- **Serialize at source**: `extractRAW_NPXLS.m` pauses robocopy before each
  Kilosort invocation (e.g. `taskkill /IM robocopy.exe /F`) and restarts it
  after. No polling needed.

---

## Session log — 2026-09-21

### What happened

Second under-load VRAM spike drop. Same root cause as 9/17 — Kilosort cold-start
allocating through the shared PCH x4 link.

**Key data** (from `gpu_log_20260918_201508.csv` and `pacifier.out.log`):

| Time | Event |
|------|-------|
| 12:55–13:00 | Kilosort run 1 — 1317 MiB, ~100 W — survived (VRAM pre-allocated mid-run) |
| 13:01:57 | Pacifier loaded 2228 MiB, took over; P1/Gen3 stable |
| ~13:12:49 | Pacifier caught CUDA unknown error — Kilosort 2 started cold VRAM allocation |
| 13:13:33 | GPU log: +1888 MiB spike → 4118 MiB total, 97 W, 63% util |
| 13:13:38 | DEVICE_LOST |
| 13:13–15:12+ | Persistent DEVICE_LOST — required reboot |

**Why Kilosort 1 survived but Kilosort 2 didn't:** run 1 was already mid-execution
(VRAM pre-allocated); run 2 started cold against the 2228 MiB pacifier baseline
and burst +1888 MiB through PCH x4 in ~330 ms.

**HAGS confirmed applied** (HwSchMode=1) — no effect. This is a PCH bandwidth
issue, not a scheduler issue.

### Applied fixes (cumulative)

| Fix | Status |
|-----|--------|
| TdrDelay/TdrDdiDelay=60 | Active |
| Defender path exclusions | Active |
| HwSchMode=1 (HAGS off) | Active — confirmed, did not prevent drop |

### Still outstanding

- **BIOS update** — 0820 (2021), predates Blackwell. Flash via ASUS EZ Flash
  from USB. Highest remaining leverage.
- **Driver clean reinstall** (currently 610.74)
- **Serialize at source** in `extractRAW_NPXLS.m` — `taskkill /IM robocopy.exe`
  before each Kilosort call, restart after.
- **VRAM-delta trigger** in `pcie_monitor.py` — Δvram > 200 MiB as unambiguous
  Kilosort-start signal; doesn't require faster polling.
