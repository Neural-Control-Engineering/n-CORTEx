function atlas = nexAtlas_initSubject(nexon, subjectID, subjectDir)
% Load or bootstrap the ephys atlas for one subject and annotate the registry.
%
%   Call from nexInit_registry (after regMap load) for each subject.
%
%   subjectID   string key as in registry.SUBJ (e.g. "subj_20115_20250407")
%   subjectDir  fully-resolved subject directory path
%
% Side-effect: writes atlasAnnotation into registry.SUBJ.(subjectID).

    try
        atlas = nexAtlas_load(subjectDir);
        nexAtlas_annotateChannels(nexon, subjectID, atlas);
    catch e
        fprintf('[nexAtlas_initSubject] skipped %s: %s\n', subjectID, e.message);
        atlas = [];
    end
end
