function segData = segmentSeries(data, segLen, dim)
    % Input:
    %   - data: The series of data points.
    %   - segLen: The length of each segment.

    % Output:
    %   - segData: A cell array containing the segmented data.
   
    % Determine the total length of the data
    totalLength = size(data,dim);

    % Calculate the number of segments    
    numSegments = floor(totalLength / segLen);

    % Initialize cell array to store segments
    segData = cell(numSegments, 1);

    % Split the data into segments
    for i = 1:numSegments
        startIndex = (i - 1) * segLen + 1;
        endIndex = i * segLen;
        segData{i} = data(:,startIndex:endIndex);
    end
end
