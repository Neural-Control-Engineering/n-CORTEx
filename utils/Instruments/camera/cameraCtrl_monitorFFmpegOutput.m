function cameraCtrl_monitorFFmpegOutput(errorStream)
    reader = java.io.InputStreamReader(errorStream);
    buffered = java.io.BufferedReader(reader);

    while true
        line = buffered.readLine();
        if isempty(line) || line == -1
            break;
        end
        disp(['[FFmpeg] ', char(line)]);
        pause(0.01);  % Avoid choking the UI
    end
end
