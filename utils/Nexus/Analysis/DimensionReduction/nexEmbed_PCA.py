# Packages
import numpy as np
import pandas as pd
import os
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

def  embedPCA(X, n_components):
    X = StandardScaler().fit_transform(X)
    # Create a PCA model.
    pca = PCA(n_components=n_components)
    
    # Fit the PCA model to the data.
    pca.fit(X)
    
    # Get the explained variance ratio
    explained_variance_ratio = pca.explained_variance_ratio_      
    
    # Transform the data using the PCA model.
    embedding = pca.transform(X)
    return embedding

    