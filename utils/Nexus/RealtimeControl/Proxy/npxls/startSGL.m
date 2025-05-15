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
        % system("cd C:\SpikeGLX\Release_v20240129-phase30\SpikeGLX\SpikeGLX.exe &")
        % system("cd C:\SpikeGLX\Release_v20240129-phase30\SpikeGLX\ & .\SpikeGLX.exe &")
        % ! cd C:\SpikeGLX\Release_v20240129-phase30\SpikeGLX\ & .\SpikeGLX.exe &
        ! cd C:\SpikeGLX\Release_v20240129-phase30\SpikeGLX\ & start "" .\SpikeGLX.exe 
        % system('.\SpikeGLX.exe &');
    end
end