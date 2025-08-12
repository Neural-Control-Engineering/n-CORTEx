def nexPy_generateArgsLabel(args):
    argsLabel = ""
    for k, v in args.items():        
        k = k.replace("_","-")
        if isinstance(v,(int,float)):
            v = str(v)            
            v = v.replace(".","p")            
        argsLabel = argsLabel + "_{}--{}".format(k,v)    
    return argsLabel

