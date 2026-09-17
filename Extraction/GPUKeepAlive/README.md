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
