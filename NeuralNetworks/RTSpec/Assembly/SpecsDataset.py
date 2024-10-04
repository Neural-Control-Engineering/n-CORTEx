# imports
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from torch.utils.data import Dataset
from glob import glob
# from torchvision import transforms
import torch
from torch.utils.data import Dataset, DataLoader
import random
import os

class SpecsDataset():
    
    def __init__(self, dataDir, folds):
        self.dataDir = dataDir        
        self.labelsFile = os.path.join(self.dataDir,"index.csv")
        index = pd.read_csv(self.labelsFile)    
        # Data fold filtering, (this enables cross validation and testing holdout)
        pattern = r'Fold(' + '|'.join(map(str,folds)) + r')\b'
        self.index = index[index.iloc[:,1].str.contains(pattern)]   
        print('index: ', self.index.shape)             

    def __len__(self):
        return len(self.index)

    def __getitem__(self, idx):
        # print('index: ', self.index.shape)             
        samplePath = os.path.join(self.dataDir,self.index.iloc[idx,1],self.index.iloc[idx,0])        
        psd = pd.read_csv(samplePath)
        psd = pd.to_numeric(psd.iloc[:,1], errors='coerce').fillna(0).values
        psd = torch.tensor(psd, dtype=torch.float32)
        label = pd.to_numeric(self.index.iloc[idx,2:], errors='coerce').fillna(0).values        
        label = torch.tensor(label, dtype=torch.float32)
        # print("label size: ",label.shape)
        # Perform z-scoring normalization
        mean = psd.mean(dim=-1, keepdim=True)
        std = psd.std(dim=-1, keepdim=True)
        psd_z = (psd - mean) / (std + 1e-7)  # Add epsilon to avoid division by zero
        psd_z = torch.cat([psd_z, mean], dim=-1) # uncomment for offset-aware normatlization        

        sample = {'PSD_z':psd_z, 'PSD':psd, 'label':label}

        return sample  
