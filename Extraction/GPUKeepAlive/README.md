# GPUKeepAlive

Keeps the RTX 5070 out of deep idle during offline extraction so it doesn't fall
off the PCIe bus (idle bus-drop → display TDR / hard hang).

## Why it's needed

`extractRAW_NPXLS.m` runs the GPU in short per-trigger bursts, each in its own
subprocess that exits when done (`runKilosort4.py`, then `runRTSort.py`). Between
those bursts — and during the CPU/disk phases (LFP filter, sync, save, zip, cloud
copy) — the GPU is fully idle. On this machine the GPU sits in a **chipset (PCH)
PCIe 3.0 x4 slot** (the CPU x16 slot is reserved for the NI DAQ), and during those
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
