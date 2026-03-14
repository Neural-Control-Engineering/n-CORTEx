function DM = stat2dm_batch(mdlObj, d1Sel)
    STAT = mdlObj.Parent.STAT;
    DM = nexOp_stackSamples(STAT, "batch", d1Sel);
end