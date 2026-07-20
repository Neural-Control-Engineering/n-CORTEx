function startSGL()
    if ispc
        [status, cmdout] = system('tasklist /FI "IMAGENAME eq SpikeGLX.exe" /NH');
        isRunning = contains(cmdout, 'SpikeGLX.exe');
    elseif isunix
        [status, cmdout] = system('ps aux | grep SpikeGLX | grep -v grep');
        isRunning = ~isempty(strtrim(cmdout));
    end

    if ~isRunning
        % make dynamic in future
        sglDir = 'C:\SpikeGLX\Release_v20240129-phase30\SpikeGLX';
        sglExe = fullfile(sglDir, 'SpikeGLX.exe');
        % Launch SpikeGLX WITHOUT inheriting MATLAB's open handles. A plain
        % `!`/cmd `start` spawns the child with handle inheritance, so a
        % SpikeGLX launched after the slrt/ncortex command tcpservers are bound
        % inherits those sockets (port 8001/8002); if SpikeGLX then outlives
        % MATLAB (e.g. a hard crash) it pins the port until it is killed —
        % WSAEADDRINUSE on the next cortex("target"). PowerShell Start-Process
        % creates the process with bInheritHandles=FALSE (no stdio redirect),
        % so SpikeGLX never receives the socket handles regardless of order.
        system(sprintf(['powershell -NoProfile -Command ' ...
            '"Start-Process -FilePath ''%s'' -WorkingDirectory ''%s''"'], ...
            sglExe, sglDir));
        % ---- ORIGINAL launch (inherits MATLAB handles → can strand port 8001).
        %      Uncomment this line and comment out the Start-Process call above
        %      to revert:
        % ! cd C:\SpikeGLX\Release_v20240129-phase30\SpikeGLX\ & start "" .\SpikeGLX.exe
    end
end