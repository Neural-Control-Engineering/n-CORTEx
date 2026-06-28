from kilosort import run_kilosort
from pathlib import Path
import os
def runKilosort4(data_dir, fileName, chanMap):
    # Convert string paths to Path objects if they're not already        
    data_dir_path = ('\\\\?\\'+data_dir)        
    fileName = ('\\\\?\\'+fileName)    
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
        filename=fileName
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