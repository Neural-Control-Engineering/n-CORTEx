function nexAtlas_save(atlas, subjectDir, sessionDate)
% Write atlas to ephys_atlas.h5 in the subject's npxls directory.
%
%   atlas       struct from nexAtlas_load / nexAtlas_initFromPrior
%   subjectDir  subject root directory
%   sessionDate (optional) 'YYYY-MM-DD' string — writes session posterior too

    if nargin < 3, sessionDate = []; end

    npxDir    = fullfile(subjectDir, 'npxls');
    if ~isfolder(npxDir), mkdir(npxDir); end
    atlasFile = fullfile(npxDir, 'ephys_atlas.h5');

    fileNew = ~isfile(atlasFile);

    % /prior/ and /config/ — written once on first save
    if fileNew
        prior = atlas.prior;
        nexAtlas_h5write(atlasFile, '/prior/channel_indices',  prior.channel_indices);
        nexAtlas_h5write(atlasFile, '/prior/channel_depths',   prior.channel_depths);
        nexAtlas_h5write(atlasFile, '/prior/P',                prior.P);
        nexAtlas_h5writeStr(atlasFile, '/prior/channel_regions',  prior.channel_regions);
        nexAtlas_h5writeStr(atlasFile, '/prior/region_acronyms',  prior.region_acronyms);
        nexAtlas_h5writeStr(atlasFile, '/prior/region_colors',    prior.region_colors);

        % Canonical eligible phases — default whitelist; extend via nexAtlas_mergeCanonical
        nexAtlas_h5writeStr(atlasFile, '/config/canonical_eligible_phases', ...
            {'spontaneous', 'Baseline'});
    end

    % /posteriors/canonical/posterior — overwritten every save (initialised to prior)
    % Phase-specific posteriors are written by nexAnalysis_ephysAtlas, not here.
    nexAtlas_h5write(atlasFile, '/posteriors/canonical/posterior', ...
        atlas.posteriors.canonical);
end

% ── private helpers ────────────────────────────────────────────────────────────

function nexAtlas_h5write(h5file, dsetPath, data)
    data = double(data);
    exists = false;
    try, h5info(h5file, dsetPath); exists = true; catch, end
    if exists
        h5write(h5file, dsetPath, data);
    else
        h5create(h5file, dsetPath, size(data), 'Datatype', 'double');
        h5write(h5file, dsetPath, data);
    end
end

function nexAtlas_h5writeStr(h5file, dsetPath, strArr)
    strArr = cellstr(string(strArr(:)));
    exists = false;
    try, h5info(h5file, dsetPath); exists = true; catch, end
    if ~exists
        h5create(h5file, dsetPath, size(strArr), 'Datatype', 'string');
    end
    h5write(h5file, dsetPath, strArr);
end
