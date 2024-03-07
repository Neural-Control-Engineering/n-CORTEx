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
    # Execute Kilosort with the specified settings and channel map
    ops, st, clu, tF, Wall, similar_templates, is_ref, est_contam_rate = run_kilosort(
        settings=settings,
        probe_name=chanMap,  # Assuming this is the name/path of the channel map file
        filename=fileName,
        results_dir=data_dir_path
    )
    # Return the results or handle them as needed
    return ops, st, clu, tF, Wall, similar_templates, is_ref, est_contam_rate