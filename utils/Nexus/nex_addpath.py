import sys
import os

def nex_addpath(folder):
    for root, dirs, files in os.walk(folder):
        sys.path.append(root)
        sys.path.append(dirs)        