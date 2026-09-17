function promoteRTSortPickle(params, experiment, subjID, sessionLabel, kSortOutPath)
% promoteRTSortPickle  Publish a detect-mode sorter to experimentModules.
%
%   promoteRTSortPickle(params, experiment, subjID, sessionLabel, kSortOutPath)
%
% For spontaneous/spontaneous-CCI sessions: copies the rt_sort.pickle
% (and sibling rtsort_results.mat if present) produced by detect-mode
% extraction into the same dated subfolder that proxy_npxls.saveSorter
% uses:
%   <experimentModules>/<experiment>/npxls/<subjID>/<Y_M_D>/
%
% resolveRTSortPickle then finds it for subsequent same-day short-trigger
% sessions (LOAD mode instead of detect). Promotion is idempotent — skipped
% if the destination pickle already exists. Errors are logged and swallowed
% so a failure here never aborts the extraction loop.

    try
        phase = string(parseSessionLabel(string(sessionLabel), "phase"));
        if ~ismember(phase, ["spontaneous", "spontaneous-CCI"])
            return;
        end

        spPickle = fullfile(kSortOutPath, "rtsort", "rt_sort.pickle");
        if ~isfile(spPickle)
            return;
        end

        dateTok = string(parseSessionLabel(string(sessionLabel), "date"));
        dgt = regexprep(char(dateTok), '\D', '');
        if numel(dgt) ~= 8
            return;
        end
        ymd = sprintf("%d_%d_%d", str2double(dgt(1:4)), str2double(dgt(5:6)), str2double(dgt(7:8)));

        destDir    = fullfile(params.paths.experimentModules, experiment, "npxls", subjID, ymd);
        destPickle = fullfile(destDir, "rt_sort.pickle");
        if isfile(destPickle)
            return;   % already promoted (or saved via real-time panel)
        end

        if ~isfolder(destDir), mkdir(destDir); end
        copyfile(spPickle, destPickle);
        spResults = fullfile(kSortOutPath, "rtsort", "rtsort_results.mat");
        if isfile(spResults)
            copyfile(spResults, fullfile(destDir, "rtsort_results.mat"));
        end
        fprintf('[extractRAW_NPXLS] auto-promoted sorter (%s) -> %s\n', sessionLabel, destDir);

    catch e
        fprintf('[extractRAW_NPXLS] sorter auto-promote skipped: %s\n', e.message);
    end
end
