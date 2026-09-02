function sevenZipArchive(sevenZip, archivePath, items)
% Compress items into a single .7z archive (LZMA2 level 1, multithreaded) then delete sources.
% Handles Windows MAX_PATH (260 chars) via subst when paths are too long.
%
%   sevenZip     path to 7z.exe  e.g. 'C:\Program Files\7-Zip\7z.exe'
%   archivePath  full path for the output archive
%   items        cell array of full file paths to compress

    % Coerce to char — MATLAB strings have numel()=1 regardless of length,
    % which breaks path arithmetic below.
    archivePath = char(archivePath);
    items       = cellfun(@char, items, 'UniformOutput', false);

    itemDir  = fileparts(items{1});
    maxLen   = max(cellfun(@numel, [items(:); {archivePath}]));
    fileArgs = strjoin(cellfun(@(f) sprintf('"%s"', f), items, 'UniformOutput', false), ' ');

    if ~ispc || maxLen < 250
        % Linux: no MAX_PATH limit, run directly.
        % Windows with short paths: same.
        cmd = sprintf('"%s" a -mx=1 -mmt=on -sdel "%s" %s', ...
            sevenZip, archivePath, fileArgs);
        [status, out] = system(cmd);
    else
        % Windows only: paths exceed MAX_PATH (260 chars).
        % Alias itemDir to a short drive letter via subst.
        % subst + 7-zip + cleanup must all run in ONE cmd.exe process — separate
        % system() calls spawn separate processes with isolated device namespaces,
        % so a subst created in call 1 is not guaranteed visible in call 2.
        substDrive   = pickFreeDrive();
        remap        = @(f) [substDrive '\' f(numel(itemDir)+2:end)];
        shortItems   = cellfun(remap, items, 'UniformOutput', false);
        shortArchive = remap(archivePath);
        shortArgs    = strjoin(cellfun(@(f) sprintf('"%s"', f), shortItems, 'UniformOutput', false), ' ');

        % Batch file: subst → 7-zip → capture exit code → unsubst → exit with 7-zip code
        batchPath = [tempname '.bat'];
        fid = fopen(batchPath, 'w');
        fprintf(fid, '@echo off\r\n');
        fprintf(fid, 'subst %s /D >nul 2>&1\r\n',                substDrive);          % clear stale mapping
        fprintf(fid, 'subst %s "%s"\r\n',                         substDrive, itemDir); % map alias
        fprintf(fid, '"%s" a -mx=1 -mmt=on -sdel "%s" %s\r\n', ...
            sevenZip, shortArchive, shortArgs);
        fprintf(fid, 'set EXITCODE=%%ERRORLEVEL%%\r\n');
        fprintf(fid, 'subst %s /D >nul 2>&1\r\n',                substDrive);          % always remove alias
        fprintf(fid, 'exit /b %%EXITCODE%%\r\n');
        fclose(fid);

        [status, out] = system(batchPath);
        delete(batchPath);
    end

    if status ~= 0
        warning('sevenZipArchive:7zipFailed', ...
            '7-zip failed for %s, falling back to zipLongPath.py:\n%s', archivePath, out);
        zipLongPathFallback(archivePath, items, sevenZip);
    end
end


function zipLongPathFallback(archivePath, items, sevenZip)
% Write a manifest and call zipLongPath.py.
% zipLongPath.py will try 7-zip via @listfile first (avoids cmd-line length
% limits without needing subst), then falls back to Python zipfile.
    pyExe = char(pyenv().Executable);
    if isempty(pyExe)
        error('sevenZipArchive:noPython', ...
            'zipLongPath.py fallback requires a configured pyenv (none set)');
    end

    scriptDir = fileparts(mfilename('fullpath'));
    pyScript  = fullfile(scriptDir, 'zipLongPath.py');

    % Write manifest: one absolute path per line
    manifestPath = [tempname '.txt'];
    fid = fopen(manifestPath, 'w', 'n', 'UTF-8');
    cellfun(@(f) fprintf(fid, '%s\n', f), items);
    fclose(fid);

    % Pass sevenZip so zipLongPath.py can try @listfile before Python zipfile
    [status, out] = system(sprintf('"%s" -u "%s" "%s" "%s" "%s"', ...
        pyExe, pyScript, manifestPath, archivePath, sevenZip), '-echo');
    delete(manifestPath);

    if status ~= 0
        error('sevenZipArchive:fallbackFailed', ...
            'zipLongPath.py fallback also failed for %s:\n%s', archivePath, out);
    end
end


function drive = pickFreeDrive()
% Return a free drive letter (Z: downward) — Windows only.
% isfolder() detects physical drives, network mounts, and existing subst aliases.
    for c = 'ZYXWVUTSRQPONM'
        if ~isfolder([c ':\'])
            drive = [c ':'];
            return;
        end
    end
    error('sevenZipArchive:noDrive', 'No free drive letter available for subst workaround');
end
