from kilosort import run_kilosort
from pathlib import Path
import os
import torch
def runKilosort4(data_dir, fileName, chanMap):
    # Convert string paths to Path objects if they're not already
    data_dir_path = ('\\\\?\\'+data_dir)
    fileName = ('\\\\?\\'+fileName)
    # Resolve and report the compute device explicitly instead of relying on
    # run_kilosort's silent None->cuda auto-select, so the run both forces GPU
    # when available and logs which device it used (subprocess stdout is captured
    # by extractRAW_NPXLS.m).
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    dev_name = torch.cuda.get_device_name(0) if torch.cuda.is_available() else "CPU"
    print(f"[runKilosort4] device={device} ({dev_name}); torch {torch.__version__}",
          flush=True)
    # Prepare settings based on the function inputs
    settings = {
        #'data_dir': data_dir_path,  # Assuming Kilosort uses this to find data
        'data_dir' : data_dir_path,
        'n_chan_bin': 385          # Adjust based on your data's channel count
        #'results_dir': results_dir_path,  # Uncomment if applicable
    }
    # Execute Kilosort. It writes all results to the kilosort4 output folder on
    # disk (results_dir defaults to data_dir/kilosort4); extractRAW_NPXLS.m then
    # moves that folder into <exp>_tN_sorted. Don't unpack the return tuple --
    # its arity changes across kilosort versions (8 in <=4.0; 9 in 4.1.x, which
    # added kept_spikes) -- so capture it whole and let the caller ignore it.
    results = run_kilosort(
        settings=settings,
        probe_name=chanMap,  # Assuming this is the name/path of the channel map file
        filename=fileName,
        device=device       # explicit GPU/CPU selection (see above)
        #results_dir=os.path.join(data_dir_path,'kilosort4')
    )
    # Return the results or handle them as needed
    return results


if __name__ == "__main__":
    # CLI entry point so MATLAB can run this in a clean subprocess
    # (avoids the nexus-env libexpat.dll vs MATLAB libexpat.dll in-process collision).
    # Kilosort writes its results to the kilosort4 output folder on disk; the
    # return value is intentionally ignored here.
    import sys
    runKilosort4(sys.argv[1], sys.argv[2], sys.argv[3])
    print("KILOSORT4_DONE")