function [NT, NT_color] = mapChan2Npxls(regMap, dataStream)
    % bin 384 channel datastream into npxls style heatmap
    % return a neuropixels tensor (NT) for video gen
    NT = zeros(96,4,size(dataStream,2));
    for i = 1:height(regMap)
        npxChan = regMap(i,:);
        channelNum = npxChan.channel{1};
        X = npxChan.X{1};
        Y = npxChan.Y{1};
        X_shift = (X-11)/16+1;
        Y_shift = floor((Y-240) / 40)+1;
        NT(Y_shift,X_shift,:) = dataStream(i,:);
    end

end