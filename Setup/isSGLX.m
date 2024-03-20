function bool = isSGLX
    % return true if system has running instance of spikeGLX
    if isunix
        % do nothing for now until SGLX for linux
        bool = 0;
    elseif ispc
        [status, res] = system('tasklist | findstr /i "SpikeGLX.exe');
        if ~isempty(res)
            bool = 1;
        else
            bool = 0;
        end
    else
        bool = 0;
    end
end