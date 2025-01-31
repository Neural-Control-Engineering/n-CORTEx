function frame = nexDeBufferFrame(buffer, frameNum)
    % Determine the highest dimension along which to concatenate frame
    maxDim = ndims(buffer.frames);  % Get the highest non-singleton dimension
    idxFrame = find(buffer.frameIds==frameNum);
    % Use the idxFrame to extract the correct frame data along the maxDim axis
    % Create a cell array of indices to index into frames
    indexCell = cell(1, maxDim);
    
    % Initialize all dimensions to slice as `:` (all elements)
    for dim = 1:maxDim
        indexCell{dim} = ':';
    end
    
    % Set the index for the maxDim dimension to the index of the frame
    indexCell{maxDim} = idxFrame;

    % Use indexing to get the requested frame
    frame = buffer.frames(indexCell{:});
end