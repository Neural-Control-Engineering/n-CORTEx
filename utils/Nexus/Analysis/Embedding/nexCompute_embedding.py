def nexCompute_embedding(nexObj, args):

    # CFG HEADER
    
    selection = args["rowSel"] # union of mask selections
    X_sel = nexObj["X"][selection,:]
    Y_sel = nexObj["Y"][selection,:]
    DF_in = nexObj.DF
    DF_in["X"] = X_sel
    DF_in["Y"] = Y_sel

    nexObj.DF_postOp = nexObj.opCfg["fcn"](DF_in, args)