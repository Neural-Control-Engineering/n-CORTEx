function params = locateDTS(params)
% Set params.paths.Data.DTS.local via folder picker and persist to nCORTExCache.
% Call this from the target app's "Locate DTS" button callback.
% On next startup, locateData will restore the saved path automatically.
    
    startDir = '';
    try
        if ~isempty(params.paths.Data.DTS.local)
            startDir = params.paths.Data.DTS.local;
        end
    catch
    end

    chosen = uigetdir(startDir, "Select DTS folder");
    if isequal(chosen, 0), return; end   % cancelled

    params.paths.Data.DTS.local = string(chosen);

    % Persist to nCORTExCache so locateData restores it on next startup.
    cacheFile = fullfile(params.paths.repo_path, 'Setup', 'nCORTExCache.mat');
    if isfile(cacheFile)
        load(cacheFile, 'cache');
    else
        cache = struct;
    end
    hn = getHostName();
    if ~isfield(cache, hn)
        cache.(hn) = struct;
    end
    cache.(hn).dtsPath = string(chosen);
    save(cacheFile, 'cache');
end
