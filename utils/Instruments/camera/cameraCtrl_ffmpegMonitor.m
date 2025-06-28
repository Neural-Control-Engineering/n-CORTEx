function cameraCtrl_ffmpegMonitor(errorStream)
    reader = java.io.InputStreamReader(errorStream);
    buffered = java.io.BufferedReader(reader);

    t = timer('ExecutionMode','fixedSpacing','Period',0.1,...
        'TimerFcn', @(~,~)readLine(buffered));
    start(t);
end

function readLine(buffered)
    if buffered.ready()
        line = buffered.readLine();
        if isempty(line) || line == -1
            stop(timerfind); delete(timerfind);
        else
            java.lang.System.out.println(['[FFmpeg] ', char(line)]);
        end
    end
end
