function DM = stat2dm_stack(mdlObj)
    STAT = mdlObj.TRAIN.STAT;    
    d1Sel=mdlObj.domain.D1;
    DM = nexOp_stackSamples(STAT, "stack", d1Sel);
end