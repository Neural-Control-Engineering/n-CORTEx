function DM = stat2dm_stack(mdlObj, d1Sel)
    STAT = mdlObj.Parent.STAT;    
    DM = nexOp_stackSamples(STAT, "stack", d1Sel);
end