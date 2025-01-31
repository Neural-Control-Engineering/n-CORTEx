function buffer = nexBufferFrame(buffer, frameNum, frame)
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
        % buffer.AxData =
    else
        % Concatenate along the highest dimension of frame
        buffer.frames = cat(maxDim + 1, buffer.frames, frame);
    end
end
