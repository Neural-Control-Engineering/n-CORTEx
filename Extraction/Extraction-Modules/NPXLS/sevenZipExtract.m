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
        warning('sevenZipExtract:7zipFailed', ...
            '7-zip extraction failed for %s, falling back to unzipLongPath.py:\n%s', archivePath, out);
        unzipLongPathFallback(archivePath, destDir);
    end
end


function unzipLongPathFallback(archivePath, destDir)
    pyExe = char(pyenv().Executable);
    if isempty(pyExe)
        error('sevenZipExtract:noPython', ...
            'unzipLongPath.py fallback requires a configured pyenv (none set)');
    end

    scriptDir = fileparts(mfilename('fullpath'));
    pyScript  = fullfile(scriptDir, 'unzipLongPath.py');
    sevenZip  = 'C:\Program Files\7-Zip\7z.exe';

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
