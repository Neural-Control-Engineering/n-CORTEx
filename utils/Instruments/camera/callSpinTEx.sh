#!/bin/bash

# Activate the Conda environment (replace 'nCORTEx' with your environment name)
source activate nCORTEx

# Define the Python script
python_script="spinTEx.py"

# Get the value of 'spinParams' from the command-line arguments
spinParams="$1"

# Check if 'spinParams' is provided
if [ -z "$spinParams" ]; then
  echo "Error: 'spinParams' argument is missing."
  exit 1
fi

# Run the Python script with 'spinParams'
echo "$spinParams"
python "$python_script" "$spinParams"
