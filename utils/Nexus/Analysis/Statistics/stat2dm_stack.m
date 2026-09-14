function DM = stat2dm_stack(mdlObj)
    STAT = mdlObj.TRAIN.STAT;    
    dnSel=mdlObj.domain.DN(1);
    DM = nexOp_stackSamples(STAT, "stack", dnSel);
end