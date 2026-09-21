function sevenZipExtract(sevenZip, archivePath, destDir)
% Extract a .7z archive. Contents land in destDir (default: same directory as archive).
% Falls back to unzipLongPath.py for Windows long paths.
%
%   sevenZip    path to 7z.exe  e.g. 'C:\Program Files\7-Zip\7z.exe'
%   archivePath full path to the .7z archive to extract
%   destDir     (optional) destination directory; defaults to fileparts(archivePath)

    archivePath = char(archivePath);
    if nargin < 3 || isempty(destDir)
        destDir = fileparts(archivePath);
    end
    destDir = char(destDir);
    maxLen      = max(numel(archivePath), numel(destDir));

    if ~ispc || maxLen < 250
        cmd = sprintf('"%s" e -y "-o%s" "%s"', sevenZip, destDir, archivePath);
        if ~ispc
            % MATLAB's own bundled LD_LIBRARY_PATH is inherited by system()
            % subprocesses and shadows the system linker path, which breaks
            % real compiled binaries like p7zip's 7z even though the exact
            % same command runs fine from a normal shell. Clear it for this
            % call only.
            cmd = ['LD_LIBRARY_PATH= ' cmd];
        end
        [status, out] = system(cmd);
    else
        % Paths exceed MAX_PATH — cmd.exe cannot pass them to 7-zip.
        % Use a batch file workaround (same pattern as sevenZipArchive).
        substDrive = pickFreeDrive();
        remap      = @(f) [substDrive '\' f(numel(destDir)+2:end)];
        shortArchive = remap(archivePath);
        shortDest    = substDrive;

        batchPath = [tempname '.bat'];
        fid = fopen(batchPath, 'w');
        fprintf(fid, '@echo off\r\n');
        fprintf(fid, 'subst %s /D >nul 2>&1\r\n',        substDrive);
        fprintf(fid, 'subst %s "%s"\r\n',                 substDrive, destDir);
        fprintf(fid, '"%s" e -y "-o%s" "%s"\r\n',         sevenZip, shortDest, shortArchive);
        fprintf(fid, 'set EXITCODE=%%ERRORLEVEL%%\r\n');
        fprintf(fid, 'subst %s /D >nul 2>&1\r\n',        substDrive);
        fprintf(fid, 'exit /b %%EXITCODE%%\r\n');
        fclose(fid);

        [status, out] = system(batchPath);
        delete(batchPath);
    end

    if status ~= 0
        if ispc
            warning('sevenZipExtract:7zipFailed', ...
                '7-zip extraction failed for %s, falling back to unzipLongPath.py:\n%s', archivePath, out);
            unzipLongPathFallback(archivePath, destDir, sevenZip);
        else
            % unzipLongPath.py's fallback path is a Windows long-path
            % workaround (subst drives, hardcoded 7z.exe) with no Linux/Mac
            % equivalent — nothing sensible to fall back to here.
            error('sevenZipExtract:7zipFailed', ...
                '7-zip extraction failed for %s:\n%s', archivePath, out);
        end
    end
end


function unzipLongPathFallback(archivePath, destDir, sevenZip)
    pyExe = char(pyenv().Executable);
    if isempty(pyExe)
        error('sevenZipExtract:noPython', ...
            'unzipLongPath.py fallback requires a configured pyenv (none set)');
    end

    scriptDir = fileparts(mfilename('fullpath'));
    pyScript  = fullfile(scriptDir, 'unzipLongPath.py');

    [status, out] = system(sprintf('"%s" -u "%s" "%s" "%s" "%s"', ...
        pyExe, pyScript, archivePath, destDir, sevenZip), '-echo');

    if status ~= 0
        error('sevenZipExtract:fallbackFailed', ...
            'unzipLongPath.py fallback also failed for %s:\n%s', archivePath, out);
    end
end


function drive = pickFreeDrive()
    for c = 'ZYXWVUTSRQPONM'
        if ~isfolder([c ':\'])
            drive = [c ':'];
            return;
        end
    end
    error('sevenZipExtract:noDrive', 'No free drive letter available');
end
