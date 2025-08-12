import pandas as pd
import os
from nexPy_generateArgsLabel import nexPy_generateArgsLabel

def nexPy_exportEmbedding(DF_embed, params):
    dataPath = params["paths"]["dataPath"]
    embedArgs = params["embedArgs"]
    method = params["embedMethod"]
    dfLabel = method + nexPy_generateArgsLabel(embedArgs)
    dfPath = os.path.join(dataPath, dfLabel)
    os.makedirs(dfPath, exist_ok=True)

    file_df = os.path.join(dfPath,"df.csv")
    file_Y = os.path.join(dfPath,"Y.csv")

    pd.DataFrame(DF_embed["df"]).to_csv(file_df, index=False, header=False)  
    pd.DataFrame(DF_embed["Y"]).to_csv(file_Y, index=False, header=False)