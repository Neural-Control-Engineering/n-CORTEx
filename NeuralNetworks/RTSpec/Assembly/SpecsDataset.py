# imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from torch.utils.data import Dataset
from glob import glob
from torchvision import transforms
import torch
from torch.utils.data import Dataset, DataLoader
import random
import os

class SpecsDataset(Dataset):
    
    def __init__(self, dataDir, folds):
        self.dataDir = dataDir        
        self.labelsFile = os.path.join(self.dataDir,"index.csv")
        index = pd.read_csv(self.labelsFile)    
        # Data fold filtering, (this enables cross validation and testing holdout)
        pattern = r'Fold(' + '|'.join(map(str,folds)) + r')\b'
        self.index = index[index.iloc[:,1].str.contains(pattern)]                

    def __len__(self):
        return len(self.index)

    def __getitem(self, idx):
        samplePath = os.path.join(self.dataDir,self.index.iLoc[idx,1],self.index.iloc[idx,0])        
        psd = pd.read_csv(samplePath)
        psd = psd[:,1]
        label = self.index.iloc[idx,2:-1]
        sample = {'PSD':psd, 'label':label}

        return sample
    
    
