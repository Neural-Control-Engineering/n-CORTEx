function buildFrameBuffer(nexObj)
    nexObj.frameBuffer.frameIds = [1:length(nexObj.DF_postOp.ax.t)];
    nexObj.frameBuffer.frames = nexObj.DF_postOp.df;
    nexObj.frameBuffer.ax = nexObj.DF_postOp.ax;
    nexObj.frameBuffer.opArgs = nexObj.opCfg.entryParams;
    nexObj.frameBuffer.aniArgs = nexObj.aniCfg.entryParams;
    
end