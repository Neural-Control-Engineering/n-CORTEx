function cameraCtrl_readFFmpegOutput(buffered)
    while buffered.ready()
        line = char(buffered.readLine());
        if ~isempty(line)
            fprintf('FFmpeg: %s\n', line);
        end
    end
end