function [dataDirs, loc] = rehydrateSession(params, modality, exp_template, dataDirs, loc, sevenZip)
% Copy an archived session from cloud to local, extract archives, re-scope.
% Handles both .7z (current) and .zip (legacy MATLAB zip) archives.
% No-ops if nidq bins are already present in dataDirs.
%
% Usage (inline debug):
%   sevenZip = 'C:\Program Files\7-Zip\7z.exe';
%   [dataDirs, loc] = rehydrateSession(params, modality, exp_template, dataDirs, loc, sevenZip)

    % Check whether nidq bins are accessible (primary signal that extraction is possible)
    nidqBins = dataDirs.nidq;
    if ~isempty(nidqBins)
        nidqBins = nidqBins(contains({nidqBins.name}, '.bin'));
    end
    if ~isempty(nidqBins)
        return;
    end

    % Find the session folder on cloud
    cloudRoot    = params.paths.Data.RAW.(modality).cloud;
    sessionMatch = dir(fullfile(cloudRoot, [exp_template '*']));
    sessionMatch = sessionMatch([sessionMatch.isdir]);
    if isempty(sessionMatch)
        return;
    end
    cloudSessionDir   = fullfile(sessionMatch(1).folder, sessionMatch(1).name);
    sessionFolderName = sessionMatch(1).name;

    % Confirm archives exist — check both .7z and .zip (legacy), root + one level deep
    archives = [dir(fullfile(cloudSessionDir, '*.7z'));  ...
                dir(fullfile(cloudSessionDir, '*.zip')); ...
                dir(fullfile(cloudSessionDir, '*', '*.7z'));  ...
                dir(fullfile(cloudSessionDir, '*', '*.zip'))];
    if isempty(archives)
        return;
    end

    % Copy session to local if not already there
    localRoot       = params.paths.Data.RAW.(modality).local;
    localSessionDir = fullfile(localRoot, sessionFolderName);
    if ~isfolder(localSessionDir)
        fprintf('[rehydrate] %s: copying from cloud...\n', sessionFolderName);
        copyfile(strcat("\\?\", cloudSessionDir), localSessionDir);
    end

    % Extract every archive found in the local session tree.
    % sevenZipExtract uses '7z e' (flat extract) — destination is the archive's own
    % folder, which is where the bins originally lived, so structure is restored correctly.
    % 7-Zip handles both .7z and .zip formats with the same command.
    localArchives = [dir(fullfile(localSessionDir, '*.7z'));  ...
                     dir(fullfile(localSessionDir, '*.zip')); ...
                     dir(fullfile(localSessionDir, '*', '*.7z'));  ...
                     dir(fullfile(localSessionDir, '*', '*.zip'))];
    for ai = 1:numel(localArchives)
        archivePath = fullfile(localArchives(ai).folder, localArchives(ai).name);
        fprintf('[rehydrate] extracting %s...\n', localArchives(ai).name);
        sevenZipExtract(sevenZip, archivePath, localArchives(ai).folder);
    end

    % Build dataDirs from local (bypass scopeRawData's cloud-preference logic)
    nidqLocal = dir(fullfile(localSessionDir, [exp_template '*nidq*']));
    imecLocal = dir(fullfile(localSessionDir, [exp_template '*imec*']));
    imecLocal = imecLocal([imecLocal.isdir]);

    if ~isempty(nidqLocal) || ~isempty(imecLocal)
        dataDirs.nidq = nidqLocal;
        dataDirs.imec = imecLocal;
        loc.nidq = 1;
        loc.imec = 1;
        % Bins confirmed present — delete archives (both .7z and legacy .zip)
        for ai = 1:numel(localArchives)
            archivePath = fullfile(localArchives(ai).folder, localArchives(ai).name);
            delete(archivePath);
            fprintf('[rehydrate] deleted %s\n', localArchives(ai).name);
        end
        fprintf('[rehydrate] %s: ready for re-extraction\n', sessionFolderName);
    else
        warning('rehydrateSession:noBinsAfterExtract', ...
            '[rehydrate] %s: archives extracted but bins not found\n', sessionFolderName);
    end
end
