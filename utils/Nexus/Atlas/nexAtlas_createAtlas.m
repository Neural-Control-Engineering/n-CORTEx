function subjectDir = nexAtlas_createAtlas(nCORTEx_app, subjectID)
% Create ephys_atlas.h5 for a subject if it does not already exist.
% Designed to be called standalone or composed into a larger initializeSubject sequence.
%
%   nCORTEx_app   nCORTEx host or target app object (exposes .params).
%                 Pass [] to force uigetdir mode regardless of subjectID.
%   subjectID     (optional) subject ID string.
%                 Provided → build subjectDir from app params.  (future: wired to
%                 nCORTEx subject selection UI; for now caller passes the ID manually)
%                 Omitted/empty → uigetdir fallback so user can point directly.
%
% Returns:
%   subjectDir    fully-resolved subject directory path, or '' if user cancelled.
%                 Pass this to nexAtlas_queryIBL, nexAtlas_registerSession, etc.

    if nargin < 2, subjectID = []; end

    % ── Resolve subjectDir ────────────────────────────────────────────────────

    if ~isempty(nCORTEx_app) && ~isempty(subjectID)
        % Params-driven path — active once nCORTEx exposes a subject selection.
        % HOOK: replace subjectID source here when nCORTEx_app.subjectSelection exists.
        params     = nCORTEx_app.params;
        experiment = params.extractCfg.experiment;
        subjectDir = fullfile(params.paths.projDir_cloud, ...
            "Experiments", experiment, "Subjects", string(subjectID));

        if ~isfolder(subjectDir)
            subjectDir = fullfile(params.paths.projDir_local, ...
                "Experiments", experiment, "Subjects", string(subjectID));
        end

        if ~isfolder(subjectDir)
            error('nexAtlas_createAtlas:notFound', ...
                'Subject directory not found for "%s"', subjectID);
        end
        fprintf('[nexAtlas_createAtlas] subject: %s\n  %s\n', subjectID, subjectDir);

    else
        % Manual fallback: user picks subjectDir directly via file browser.
        subjectDir = uigetdir('', 'Select subject directory');
        if isequal(subjectDir, 0)
            subjectDir = '';
            fprintf('[nexAtlas_createAtlas] cancelled.\n');
            return;
        end
        fprintf('[nexAtlas_createAtlas] subject dir: %s\n', subjectDir);
    end

    % ── Create atlas if absent ────────────────────────────────────────────────

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');

    if isfile(atlasFile)
        fprintf('[nexAtlas_createAtlas] atlas already exists — nothing to do.\n  %s\n', atlasFile);
        return;
    end

    regMap = nexAtlas_loadRegMap(subjectDir);
    atlas  = nexAtlas_initFromPrior(regMap);
    nexAtlas_save(atlas, subjectDir);

    fprintf('[nexAtlas_createAtlas] created: %s\n', atlasFile);
end
