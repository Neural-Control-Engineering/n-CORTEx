function DM = stat2dm_batch(mdlObj)
    STAT = mdlObj.TRAIN.STAT;    
    d1Sel=mdlObj.domain.D1;
    DM = nexOp_stackSamples(STAT, "batch", d1Sel);
end