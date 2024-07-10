#!/bin/bash

# Check if ~/nCORTEx_cloud/ is a directory
if [ ! -d ~/nCORTEx_cloud/ ]; then
    echo "Error: ~/nCORTEx_cloud/ is not a directory."
    exit 1
fi

# Get the branch name from command line argument, default to 'main' if not provided
selected_branch=${1:-main}

# Change directory to the specified path
cd ~/Code_Repo/n-CORTEx/ || { echo "Error: Directory ~/Code_Repo/n-CORTEx/ not found"; exit 1; }

# Switch to the selected branch
git checkout "$selected_branch" || { echo "Error: Failed to switch to branch $selected_branch"; exit 1; }

# Pull the latest changes from the repository
git pull || { echo "Error: Failed to pull latest changes"; exit 1; }

# Run MATLAB command
matlab -nosplash -nodesktop -r "try, cortex('host'); catch ME, disp(ME.message); end;"
