function storeFrameBuffer(nexObj, args)
    % write frameBuffer to dfID-associated column according to its
    % configurations
    try % if animation config present
        aniArgs = nexObj.aniCfg.entryParams;
    catch e        
        disp(getReport(e));
        disp("no animation configuration found")
        aniArgs = [];
    end
    opArgs = nexObj.opCfg.entryParams;
    operationID = compileOperationID(nexObj);
    frameBufferID = sprintf("frameBuffer_%s%s", strrep(nexObj.dfID,"_","-"), operationID);
    frameBuffer_prev = grabDataFrame(nexObj.nexon, frameBufferID, []);
    % save current frame for next retrieval
    nexObj.frameBuffer.currentFrame = nexObj.frameNum;
    try
        % compare configs    
        % ANIMATION CFG
        if ~isempty(aniArgs)
            aniArgDiffs = cellfun(@(x) compareArgs(x.aniArgs, aniArgs), frameBuffer_prev, "UniformOutput", true); % at each frame buffer in frameBuffer_prev, return cfg comparisons for ani and op args
        else
            aniArgDiffs = 1;
        end
        % OPERATION CFG
        opArgDiffs = cellfun(@(x) compareArgs(x.opArgs, opArgs), frameBuffer_prev, "UniformOutput", true);
        allDiffs = aniArgDiffs & opArgDiffs;
        isNew = ~any(allDiffs == 1); % if none of the frameBuffers have both cfgs already stored, together in one buffer
        if isNew % append new
            frameBuffer_update = [frameBuffer_prev; nexObj.frameBuffer]; % concatenate with new frame buffer
            % write back
            writeDataframe(nexObj.nexon, frameBufferID, frameBuffer_update,[]);
        else % write back to existing frame buffer
            frameBuffer_prev{allDiffs == 1} = nexObj.frameBuffer;
            writeDataframe(nexObj.nexon, frameBufferID, frameBuffer_prev,[]);
        end
    catch e
        disp(getReport(e));
        disp("the frame buffer could not be appended, overwriting existing buffer");
        writeDataframe(nexObj.nexon, frameBufferID, {nexObj.frameBuffer}, [])
    end
    
end