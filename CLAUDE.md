# n-CORTEx — CLAUDE.md

## Project Overview

n-CORTEx ("cortex") is a real-time experimentation platform for configuring, deploying, and extracting data from multi-modal behavioral and neural recording experiments. It runs across a distributed network of computers — one **host** and one or more **targets** — using MATLAB/Simulink Real-Time as the core runtime.

The **Nexus** analysis framework lives in `utils/Nexus/` and handles all real-time and offline neural data analysis.

---

## System Requirements

- **MATLAB 2024a** with Simulink, Simulink Real-Time, Simulink Coder, MATLAB Coder
- **Python 3.10+** via miniconda — conda env: `nexus` at `~/miniconda3/envs/nexus/`
- Spinnaker SDK (camera support)
- Real-time OS target: QNX, VxWorks, or RTLinux

---

## Entry Points

| Command | Purpose |
|---------|---------|
| `cortex("host")` | Launch host-side GUI (`nCORTEx_host.mlapp`) |
| `cortex("target")` | Launch target-side GUI (`nCORTEx_target.mlapp`) |
| `startNexus(params, DTS)` | Initialize the Nexus analysis framework |

---

## Repository Structure

```
n-CORTEx/
├── cortex.m                  # Top-level router (host vs target)
├── nCORTEx_host.mlapp        # Host GUI application
├── nCORTEx_target.mlapp      # Target GUI application
├── Extraction/               # Modality-specific data extractors (AP, LFP, NPXLS, CAMERA, PHOTOM, SLRT, ...)
├── SignalProc/               # Signal processing pipeline (preProc, spectralExtraction, filtering)
├── Setup/                    # Configuration: setPaths, setExtractionParams, setAnalysisParameters, setAcquisitionParams
├── Visualization/            # Neural data visualization (Npxls, RealtimeVis, Stim)
├── postProc/                 # Post-processing operations
├── Validation/               # Data validation and correction
├── Labeling/                 # RTSpec labeling system
├── deeplabcut/               # DeepLabCut pose tracking integration
├── BatchScripts/             # Batch processing scripts
├── CodeGen/                  # Simulink code generation
├── dataLoading/              # Data loading utilities
├── dirHandler/               # Directory management
├── logging/                  # Logging infrastructure
├── constructor/              # Module construction utilities
└── utils/
    ├── Nexus/                # Core Nexus analysis framework (see utils/Nexus/CLAUDE.md)
    ├── fieldtrip-20230522/   # FieldTrip neurophysiology toolbox
    ├── eeglab_current/       # EEGLab EEG processing suite
    └── Kilosort4/            # Spike sorting
```

---

## Architecture

### Two-Machine Model

**Host computer**: Experiment design, device configuration, session control, real-time connection management. Runs `nCORTEx_host.mlapp`.

**Target computer(s)**: Real-time processing via Simulink Real-Time, hardware communication, data acquisition. Runs `nCORTEx_target.mlapp`.

### Data Hierarchy

Experiments are organized as: `Project → Experiment → Subject → Session`

### Data Format

Core data structure is the **DTS** (Data Table/Struct), passed through extraction, processing, and analysis pipelines. Raw recordings are stored in SpikeGLX format (`.bin` + meta) for Neuropixels data.

---

## Key Configuration Files

- `Setup/setPaths.m` — master path configuration for all machines
- `Setup/setExtractionParams.m` — extraction parameter definitions
- `Setup/setAnalysisParameters.m` — analysis parameter definitions
- `Setup/setAcquisitionParams.m` — hardware acquisition setup
- `rtspec.yaml` — conda environment spec (Python 3.10, PyTorch, CUDA 12.4)
- `expmntCfg_template.mat` — experiment configuration template

---

## Development Conventions

- **Primary language**: MATLAB. Python is used for neural network training and embedding (UMAP, CEBRA).
- **MATLAB handle classes** are used for all major objects (`Nexon`, UI panels, etc.).
- The `.asv` files are MATLAB autosave artifacts — do not edit them directly.
- Simulink modules (`.slx`) define experimental paradigms and are deployed to targets.
- Path management is centralized in `Setup/setPaths.m` — new directories should be registered there.

---

## Active Development Branch

`Dev_MS_realtimeControl_antigravity` — focused on real-time control systems and antigravity paradigms. Recent work includes SSM/LDA modeling, CEBRA/visualization improvements, and robust SLRT routing.
