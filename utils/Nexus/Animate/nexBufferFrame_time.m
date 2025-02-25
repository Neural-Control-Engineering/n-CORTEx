function buffer = nexBufferFrame_time(buffer, frameNum, frame, timePt, ax)
    % Check if frameNum already exists in frameIds
    if any(buffer.frameIds == frameNum)
        % Do nothing if frameNum already exists
        return;
    end

    % Append frameNum to frameIds
    buffer.frameIds = [buffer.frameIds; frameNum];
    
    % Determine the highest dimension along which to concatenate frame
    maxDim = ndims(frame);  % Get the highest non-singleton dimension    
    if isempty(buffer.frames)
        % Initialize frames if empty
        buffer.frames = frame;      
        % assign axes to buffer
        axFields = fieldnames(ax);        
        for i=1:length(axFields)
            axField = axFields{i};
            buffer.ax.(axField) = ax.(axField);
        end
        buffer.ax.t = timePt;
    else
        % Concatenate along the highest dimension of frame
        buffer.frames = cat(maxDim + 1, buffer.frames, frame);
        % buffer timepoints        
        buffer.ax.t = [buffer.ax.t, timePt];       
        % sort by time
        [buffer.ax.t, sortIdx] = sort(buffer.ax.t,2);
        buffer.frames  = buffer.frames(:,:,sortIdx);
        buffer.frameIds = buffer.frameIds(sortIdx);
        % disp(size(buffer.frames));
        % disp(buffer.ax.t);
    end
    
end
