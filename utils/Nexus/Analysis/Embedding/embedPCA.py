from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

def embedPCA(DF, args):

    # CFG HEADER
    n_components = args["n_components"] # default = 10

    X = DF["X"]   

    X_norm = StandardScaler().fit_transform(X)

    pca = PCA(n_components)

    pca.fit(X_norm)

    DF_postOp = {}
    DF_postOp["df"] = pca.transform(X)
    DF_postOp["Y"] = DF["Y"]

    return DF_postOp