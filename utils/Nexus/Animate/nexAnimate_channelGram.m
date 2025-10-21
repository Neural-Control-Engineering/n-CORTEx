function nexAnimate_channelGram(nexon, shank, channelGram, args)
    % tic
    % CFG HEADER
    windowLen = args.windowLen; % default = 100
    stride = args.stride; % default = 20
    frameNum = args.frameNum; % default = 1
    
    frameNum = channelGram.frameNum;
    preBufferLen = channelGram.preBufferLen; % time prior to event (seconds)
    opArgs = channelGram.opCfg.entryParams;
    opArgs.frameNum = channelGram.frameNum;
    visArgs = channelGram.visCfg.entryParams;
    aniArgs = channelGram.aniCfg.entryParams;
    
    % check if current opCfg matches buffered opCfg
    prevOpArgs = channelGram.frameBuffer.opArgs;
    prevAniArgs = channelGram.frameBuffer.aniArgs;
    isMatch_op = compareArgs(channelGram.opCfg.entryParams, prevOpArgs);
    isMatch_ani = compareArgs(channelGram.aniCfg.entryParams, prevAniArgs);
    if (~isMatch_op) || (~isMatch_ani)       
        % disp("cfg has been updated, restarting buffer")
        channelGram.frameBuffer.frameIds = [];
        channelGram.frameBuffer.frames = [];
        channelGram.frameBuffer.ax = struct;
    end
    if any(channelGram.frameBuffer.frameIds == frameNum) % if opArgs hasn't changed and the frame already exists               
        [df_out, ax] = nexDeBufferFrame(channelGram.frameBuffer, frameNum);        
    else % operate for a new frame       
        % disp("could not recover frame buffer, creating a new one")
        df = channelGram.DF.df;
        % pad according to windowLen            
        df_pad = nex_padDfZeros(df, windowLen);
        try % attempt slice, if fails, start from beginning frame number and return
            df_slice = df_pad(:,frameNum:frameNum+windowLen);                          
        catch e
            disp(getReport(e));
            fprintf("animation failed at frame number %d", channelGram.frameNum);
            fprintf("starting again from frame number 1");
            channelGram.frameNum=1;
            return;
        end
        %% OPERATE
        % operate on dataframe with configured fcn        
        opFcn_out = channelGram.opCfg.opFcn(df_slice, opArgs);        
        % recover operation outputs
        df_out = opFcn_out.df;
        ax = opFcn_out.ax;
    end
    % frame to time conversion
    t_frame = frameNum / opArgs.Fs - preBufferLen;
    % store opArgs/aniArgs in frameBuffer for comparison on next interation
    channelGram.frameBuffer.opArgs = channelGram.opCfg.entryParams;
    channelGram.frameBuffer.aniArgs = channelGram.aniCfg.entryParams;

    % Buffer frames (for faster plotting on next go-around)
    try
        channelGram.frameBuffer = nexBufferFrame_time(channelGram.frameBuffer,frameNum, df_out, t_frame, ax);    
    catch e % if buffer fails (for any reason) clear buffer and try again
        disp(getReport(e));
        % REFRESH
        channelGram.frameBuffer.frameIds = [];
        channelGram.frameBuffer.frames = [];
        channelGram.frameBuffer.ax = struct;
        % OPERATE
        df = channelGram.DF.df;
        df_pad = nex_padDfZeros(df, windowLen);
        df_slice = df_pad(:,frameNum:frameNum+windowLen);                           
        % operate on dataframe with configured fcn        
        opFcn_out = channelGram.opCfg.opFcn(df_slice, opArgs);        
        % recover operation outputs
        df_out = opFcn_out.df;
        ax = opFcn_out.ax;        
        channelGram.frameBuffer = nexBufferFrame_time(channelGram.frameBuffer,frameNum, df_out, t_frame, ax);    
    end

    % Store DF_postOp
    % ss = size(channelGram.frameBuffer.frames)

    channelGram.DF_postOp.df = channelGram.frameBuffer.frames;    
    channelGram.DF_postOp.ax = channelGram.frameBuffer.ax;

    % update children objs
    try
        % nex_updateChildren(nexon, channelGram);
    catch e
        disp(getReport(e));
    end

    %% VISUALIZE            
    % channelGram.visCfg.visFcn(nexon, shank, channelGram, df_out, ax, visArgs);    
    channelGram.visCfg.visFcn(nexon, channelGram, visArgs);
    channelGram.Figure.panel1.tiles.Axes.channelGram.Parent.Parent.Title.String=(sprintf("%0f (s)",t_frame));        
    drawnow;

    % save buffer; using previous dfID
    % disp(obj.dfID);
    % frameBufferID = sprintf("frameBuffer_chg_%s",channelGram.dfID);
    % try DTS standard columns
    dtsMemberID = sprintf("%s--%s", channelGram.classID, func2str(channelGram.opCfg.opFcn));
    % compile MatchArgs = opArgs + visArgs    
    matchArgs = mergeStructs(channelGram.opCfg.entryParams, channelGram.aniCfg.entryParams);
    dtsIdx = [];
    % [colIdx] = nex_isDtsMember(dtsMemberID, matchArgs, dtsIdx);
    if ~nex_isDtsMember(channelGram.nexon, dtsMemberID, matchArgs, dtsIdx)       
        storeFrameBuffer(channelGram, []);
    end
    % writeDf(nexon,frameBufferID, channelGram.frameBuffer,[]);            
    
    % step to next frame    
    if isempty(channelGram.dataFrame) % if  not using old 'df'
        % channelGram.frameNum = mod(channelGram.frameNum+stride,size(channelGram.DF_postOp.df,3)-windowLen/2);
        % channelGram.frameNum = mod(channelGram.frameNum+stride,size(channelGram.DF_postOp.df,3));
        channelGram.frameNum = mod(channelGram.frameNum+stride,max(channelGram.frameBuffer.frameIds));
        % disp(channelGram.frameNum)
    else       
        channelGram.frameNum = mod(channelGram.frameNum+stride,size(channelGram.dataFrame,2)-windowLen/2);
        % if channelGram.frameNum == 0
        if (channelGram.frameNum+stride) > (size(channelGram.dataFrame,2)-windowLen) % restart if breaching windowLen boundary
            channelGram.frameNum=1;
        end
    end
    % toc
end