function DM = stat2dm_batch(mdlObj)
    STAT = mdlObj.TRAIN.STAT;    
    dnSel=mdlObj.domain.DN(1);
    DM = nexOp_stackSamples(STAT, "batch", dnSel);
end