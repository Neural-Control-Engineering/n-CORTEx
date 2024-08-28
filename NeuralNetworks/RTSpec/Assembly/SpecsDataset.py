# imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from torch.utils.data import Dataset
from glob import glob
import nibabel as nib
from torchvision import transforms
import torch
from torch.utils.data import Dataset, DataLoader
import random
import os

class SpecsDataset(Dataset):
    
    def __init__(self, psdDir, labelsFile):
        self.psdDir = psdDir        
        self.labelsFile = labelsFile
        self.psdLabels = pd.read_csv(self.labelsFile)    

    def __len__(self):
        return len(self.psdLabels)

    def __getitem(self, idx):
        samplePath = os.path.join(self.psdDir,self.psdLabels.iloc[idx,0])
        # psd = readPsd
        label = self.psdLabels.iloc[idx,1]
        sample = {'PSD':psd, 'label':label}

        return sample
    
    
