function picklePath = resolveRTSortPickle(params, sessionLabel)
% resolveRTSortPickle  Find a pre-trained rt_sort.pickle for this session.
%
%   picklePath = resolveRTSortPickle(params, sessionLabel)
%
% Locates the sorter saved by proxy_npxls.saveSorter, whose layout is
%   <experimentModules>/<experiment>/npxls/<subject>/<Y_M_D>/rt_sort.pickle
% so extractRAW can sort a short trigger with a richer-context sorter (e.g. a
% 30 s model) instead of learning one from the trigger itself.
%
% The session is pinned by its DATE (parsed from sessionLabel): among the
% subject-level folders under .../npxls, pick the one whose name carries the
% session's subject and date (e.g. "10259-20260803"), then the NEWEST
% rt_sort.pickle beneath it (a subject folder may hold several dated save
% subfolders). Returns "" when nothing matches — the caller then falls back to
% detection (runRTSort.py detect mode).

    picklePath = "";

    % Base: <experimentModules>/<experiment>/npxls. experimentModules is expected
    % on params.paths; bail quietly (→ detection) if the config isn't present.
    try
        experiment = params.extractCfg.experiment;
    catch
        try, experiment = params.experiment; catch, return; end
    end
    try
        base = fullfile(params.paths.experimentModules, experiment, "npxls");
    catch
        return;
    end
    if ~isfolder(base), return; end

    subject = string(parseSessionLabel(string(sessionLabel), "subj"));  % e.g. "10259"
    dateTok = "";
    try, dateTok = string(parseSessionLabel(string(sessionLabel), "date")); catch, end

    % Session recording date → saveSorter's dated-subfolder form. The date token
    % is YYYYMMDD (e.g. "20260817"); saveSorter names the subfolder with
    % sprintf("%d_%d_%d", y, m, d) (no zero-pad, e.g. "2026_8_17"). Convert so we
    % match the SUBFOLDER (the recording date), not the subject-tag folder.
    dgt = regexprep(char(dateTok), '\D', '');   % strip any separators
    if numel(dgt) ~= 8, return; end             % no usable date → detect fallback
    ymd = sprintf("%d_%d_%d", str2double(dgt(1:4)), str2double(dgt(5:6)), str2double(dgt(7:8)));

    % Subject-level folder(s): name carries the subject (the trailing tag, e.g.
    % "-20260803", is a constant subject id, NOT the recording date).
    d     = dir(base);
    d     = d([d.isdir] & ~ismember({d.name}, {'.','..'}));
    names = string({d.name});
    if strlength(subject) > 0
        subjFolders = names(contains(names, subject));
    else
        subjFolders = names;
    end

    % EXACT date match: <subjectFolder>/<ymd>/rt_sort.pickle. No newest-fallback —
    % a session must use its OWN date's sorter; no match → "" (detect fallback).
    for i = 1:numel(subjFolders)
        cand = fullfile(base, subjFolders(i), ymd, "rt_sort.pickle");
        if isfile(cand)
            picklePath = string(cand);
            return;
        end
    end
end
