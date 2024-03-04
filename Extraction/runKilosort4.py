from kilosort import run_kilosort
from pathlib import Path
def runKilosort4(data_dir, results_dir, chanMap):
    # Convert string paths to Path objects if they're not already
    data_dir_path = Path(data_dir)
    results_dir_path = Path(results_dir)
    # Ensure the results directory exists
    # results_dir_path.mkdir(parents=True, exist_ok=True)
    # Prepare settings based on the function inputs
    settings = {
        'data_dir': data_dir_path,  # Assuming Kilosort uses this to find data
        'n_chan_bin': 385,          # Adjust based on your data's channel count
        'results_dir': results_dir_path,  # Uncomment if applicable
    }
    # Execute Kilosort with the specified settings and channel map
    ops, st, clu, tF, Wall, similar_templates, is_ref, est_contam_rate = run_kilosort(
        settings=settings,
        probe_name=chanMap  # Assuming this is the name/path of the channel map file
    )
    # Return the results or handle them as needed
    return ops, st, clu, tF, Wall, similar_templates, is_ref, est_contam_rate