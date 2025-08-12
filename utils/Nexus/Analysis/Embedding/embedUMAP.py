import umap
from sklearn.preprocessing import StandardScaler

def embedUMAP(DF, args):

    # CFG HEADER
    n_components = args["n_components"]  # default = 2
    n_neighbors = args.get("n_neighbors", 15)  # default = 15
    min_dist = args.get("min_dist", 0.1)  # default = 0.1

    X = DF["X"]

    # Normalize the data using StandardScaler
    X_norm = StandardScaler().fit_transform(X)

    # Initialize and fit the UMAP model
    umap_model = umap.UMAP(n_components=n_components, n_neighbors=n_neighbors, min_dist=min_dist)

    # Fit the UMAP model and transform the data
    X_umap = umap_model.fit_transform(X_norm)

    # Create the output dictionary
    DF_postOp = {}
    DF_postOp["df"] = X_umap
    DF_postOp["Y"] = DF["Y"]

    return DF_postOp
