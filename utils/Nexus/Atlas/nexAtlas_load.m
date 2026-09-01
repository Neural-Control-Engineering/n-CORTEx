function atlas = nexAtlas_load(subjectDir)
% Load subject atlas from ephys_atlas.h5, or bootstrap from the NTE prior.
%
%   atlas struct fields:
%     .prior.channel_indices      (n_ch,)      Neuropixels channel indices
%     .prior.channel_depths       (n_ch,)      µm from probe tip (0 = deepest)
%     .prior.channel_regions      (n_ch,)      hard NTE region label per channel
%     .prior.region_acronyms      (n_reg,)     unique region labels
%     .prior.region_colors        (n_reg,)     hex color per region
%     .prior.P                    (n_ch×n_reg) Gaussian-blurred NTE prior
%     .posteriors.canonical       (n_ch×n_reg) merged canonical posterior (read target)
%     .reference                  struct       IBL feature distributions
%     .sessions                   struct       per-session records

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');

    if isfile(atlasFile)
        atlas = nexAtlas_readHDF5(atlasFile);
    else
        regMap = nexAtlas_loadRegMap(subjectDir);
        atlas  = nexAtlas_initFromPrior(regMap);
        nexAtlas_save(atlas, subjectDir);
        fprintf('[nexAtlas_load] initialised ephys_atlas.h5 from NTE prior: %s\n', subjectDir);
    end
end

% ── private ───────────────────────────────────────────────────────────────────

function atlas = nexAtlas_readHDF5(atlasFile)
    p = struct();
    p.channel_indices  = h5read(atlasFile, '/prior/channel_indices');
    p.channel_depths   = h5read(atlasFile, '/prior/channel_depths');
    p.P                = h5read(atlasFile, '/prior/P');
    p.channel_regions  = string(h5read(atlasFile, '/prior/channel_regions'));
    p.region_acronyms  = string(h5read(atlasFile, '/prior/region_acronyms'));
    p.region_colors    = string(h5read(atlasFile, '/prior/region_colors'));

    atlas.prior     = p;
    atlas.reference = struct();
    atlas.sessions  = struct();

    % Canonical posterior — fall back to prior if no sessions registered yet
    try
        atlas.posteriors.canonical = h5read(atlasFile, '/posteriors/canonical/posterior');
    catch
        atlas.posteriors.canonical = p.P;
    end

    % Per-session phase tags (lightweight — no heavy arrays loaded at startup)
    % Full session labels exceed MATLAB's 63-char fieldname limit, so a safe
    % short key is used as the struct field; the original label is in .label.
    try
        info = h5info(atlasFile, '/sessions');
        for i = 1:numel(info.Groups)
            fullKey = info.Groups(i).Name;
            fullKey = fullKey(max(strfind(fullKey,'/'))+1:end);
            safeKey = sessionFieldname(fullKey);
            try
                atlas.sessions.(safeKey).label = fullKey;
                atlas.sessions.(safeKey).phase = ...
                    char(h5read(atlasFile, ['/sessions/' fullKey '/phase']));
            catch
            end
        end
    catch
    end
end


function k = sessionFieldname(label)
% Derive a valid MATLAB identifier (<=63 chars) from a session label.
% Appends an 8-char hex hash so labels that share a 54-char prefix stay unique.
    safe = regexprep(char(label), '[^a-zA-Z0-9]', '_');
    if ~isempty(safe) && ~isletter(safe(1)), safe = ['s' safe]; end
    if numel(safe) <= 63
        k = safe;
        return;
    end
    hash = sprintf('%08x', mod(sum(double(char(label)) .* (1:numel(label))), 2^32));
    k = [safe(1:54) '_' hash];   % 54 + '_' + 8 = 63
end
