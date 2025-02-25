function frameBuffer = retrieveFrameBuffer(nexObj)
    % read frameBuffer to dfID-associated column according to its
    % configurations; if a frameBuffer with matching cfg already exists -
    % return it
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
    frameBuffer_read = grabDataFrame(nexObj.nexon, frameBufferID,[]);
    try
        % compare cfgs    
        % ANIMATION CFG
        if ~isempty(aniArgs)
            aniArgDiffs = cellfun(@(x) compareArgs(x.aniArgs, aniArgs), frameBuffer_read, "UniformOutput", true); % at each frame buffer in frameBuffer_prev, return cfg comparisons for ani and op args
        else
            aniArgDiffs = 1;
        end
        % OPERATION CFG
        opArgDiffs = cellfun(@(x) compareArgs(x.opArgs, opArgs), frameBuffer_read, "UniformOutput", true);
        allDiffs = aniArgDiffs & opArgDiffs;
        isNew = ~any(allDiffs == 1); % if none of the frameBuffers have both cfgs already stored, together in one buffer    
        if isNew
            frameBuffer = [];
        else        
            frameBuffer = frameBuffer_read{allDiffs == 1};
        end
    catch e
        disp(getReport(e));
        disp("could not retrieve frame buffer, returning an empty buffer");
        frameBuffer = [];
    end
end