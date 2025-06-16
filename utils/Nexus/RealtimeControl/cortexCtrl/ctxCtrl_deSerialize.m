function ctx_deSerial = ctxCtrl_deSerialize(ctx_rx, elemID)
    maxDim = 3;
    numCmds = numel(enumeration('ctrlKey'));
    bufferSize = 10;
    switch elemID
        case "CMD"
            ctx_deSerial = ctx_rx';
        case "PYD"
            % ctx_deSerial = [];
            % ctx_deSerial = uint8(zeros(numCmds,bufferSize));
            ctx_deSerial = reshape(ctx_rx,[bufferSize,numCmds])';
        case "SZE"
            rxLen = length(ctx_rx);
            ctx_deSerial = reshape(ctx_rx, [maxDim,round(rxLen/maxDim)])';
    end
end