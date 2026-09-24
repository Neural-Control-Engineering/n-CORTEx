function nexAtlas_runUnitMatchBG(subjectDir, sorterTag, statusFile)
% Standalone entry point for running nexAtlas_runUnitMatch as a separate
% background MATLAB process (launched via `matlab -batch` from
% nexObj_ephysAtlas.runUnitMatch), so the interactive session's UI and
% command line stay responsive during the run. MATLAB is single-threaded:
% within one process there is no way to keep the UI responsive during
% UnitMatch's long, tight, uninterruptible computation — a separate OS
% process is the only real fix. Deliberately not parfeval/parpool: this
% codebase hit repeated Parallel Computing Toolbox AttachedFiles crashes
% elsewhere: a plain background MATLAB process avoids that machinery
% entirely.
%
% Progress is reported by writing to statusFile (a small JSON file),
% polled by the interactive session's timer, rather than the usual
% function-handle progressFcn — a handle can't cross process boundaries.
%
%   subjectDir  fully-resolved subject directory (char)
%   sorterTag   'KS' or 'RT' (char)
%   statusFile  full path to the JSON status file to write progress to.
%               Written atomically (temp file + movefile) so a concurrent
%               reader never sees a partial write.

    repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    addpath(genpath(fullfile(repoRoot, 'utils', 'UnitMatch', 'MATLAB')));
    addpath(fullfile(repoRoot, 'utils', 'npy-matlab-master', 'npy-matlab'));
    addpath(fullfile(repoRoot, 'Extraction', 'Extraction-Modules', 'NPXLS'));
    addpath(fullfile(repoRoot, 'utils', 'Nexus', 'Atlas'));

    progressFcn = @(frac, label) writeStatus_(statusFile, frac, label, false, false);

    ok = false;
    try
        ok = nexAtlas_runUnitMatch(subjectDir, sorterTag, progressFcn);
    catch e
        fprintf('[nexAtlas_runUnitMatchBG] uncaught error:\n%s\n', getReport(e, 'extended'));
    end

    if ok
        finalLabel = 'Done.';
    else
        finalLabel = 'UnitMatch run finished without success — see this process''s log for detail.';
    end
    writeStatus_(statusFile, 1, finalLabel, true, ok);
end

function writeStatus_(statusFile, frac, label, done, ok)
    s = struct('frac', frac, 'label', label, 'done', done, 'ok', ok, ...
        'timestamp', char(datetime('now')));
    tmpFile = [statusFile '.tmp'];
    fid = fopen(tmpFile, 'w');
    fwrite(fid, jsonencode(s));
    fclose(fid);
    movefile(tmpFile, statusFile);
end
