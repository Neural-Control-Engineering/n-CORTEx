function nexAtlas_reconcileCatalog(subjectDir, sorterTag)
% Propagate UnitMatch global IDs into the unit catalog.
%
% nexAtlas_registerSession assigns cosine-similarity IDs to the catalog and
% writes them to /units/sessions/<label>/<sorterTag>/cosine_global_ids.
% nexAtlas_runUnitMatch overwrites /units/sessions/<label>/<sorterTag>/global_ids
% with its own cross-session IDs.
%
% This function uses cosine_global_ids as the bridge to re-index catalog
% entries to UnitMatch IDs, merging entries that UnitMatch collapses.
% After this call the catalog's global_id column is authoritative and consistent
% with the session records.
%
% Run after nexAtlas_runUnitMatch, before nexAtlas_recomputePosteriors.

    if nargin < 2, sorterTag = 'KS'; end

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    if ~isfile(atlasFile)
        error('nexAtlas_reconcileCatalog:noAtlas', 'ephys_atlas.h5 not found: %s', atlasFile);
    end

    catalog = nexAtlas_loadCatalog(subjectDir);
    if catalog.n_units == 0
        fprintf('[nexAtlas_reconcileCatalog] catalog empty — nothing to reconcile.\n');
        return;
    end

    % ── Build cosine→UnitMatch ID map from all registered sessions ────────────
    % For each unit: cosine_gid (catalog key) → um_gid (UnitMatch key)
    cosine2um = containers.Map('KeyType','double','ValueType','double');

    try
        sessInfo = h5info(atlasFile, '/sessions');
    catch
        fprintf('[nexAtlas_reconcileCatalog] no sessions in atlas.\n');
        return;
    end

    nMapped = 0;
    for i = 1:numel(sessInfo.Groups)
        sessPath = sessInfo.Groups(i).Name;
        sortPath = [sessPath '/' char(sorterTag)];
        try
            h5info(atlasFile, sortPath);
        catch
            continue;  % this session has no data for this sorter
        end
        try
            cosine_ids = double(h5read(atlasFile, [sortPath '/cosine_global_ids']));
            um_ids     = double(h5read(atlasFile, [sortPath '/global_ids']));
        catch
            continue;  % UnitMatch not yet run for this session
        end

        for u = 1:numel(cosine_ids)
            cid = cosine_ids(u);
            uid = um_ids(u);
            if isKey(cosine2um, cid)
                if cosine2um(cid) ~= uid
                    fprintf('[nexAtlas_reconcileCatalog] warning: cosine_id %d maps to UM IDs %d and %d across sessions — keeping first\n', ...
                        cid, cosine2um(cid), uid);
                end
            else
                cosine2um(cid) = uid;
                nMapped = nMapped + 1;
            end
        end
    end

    fprintf('[nexAtlas_reconcileCatalog] %d cosine→UnitMatch ID mappings found\n', nMapped);
    if nMapped == 0
        fprintf('  Run nexAtlas_runUnitMatch first.\n');
        return;
    end

    % ── Remap catalog global_ids ──────────────────────────────────────────────
    old_ids = catalog.global_id;
    new_ids = old_ids;

    for i = 1:numel(old_ids)
        if isKey(cosine2um, old_ids(i))
            new_ids(i) = cosine2um(old_ids(i));
        end
    end

    % ── Merge entries that UnitMatch collapsed to the same global ID ──────────
    [uniq_new, ~, grp] = unique(new_ids);
    n_uniq = numel(uniq_new);

    if n_uniq == catalog.n_units
        % No merges needed — just remap IDs
        catalog.global_id = new_ids;
        fprintf('[nexAtlas_reconcileCatalog] remapped %d IDs, no merges.\n', catalog.n_units);
    else
        fprintf('[nexAtlas_reconcileCatalog] merging %d catalog entries → %d unique units\n', ...
            catalog.n_units, n_uniq);
        catalog = mergeCatalogEntries(catalog, grp, uniq_new);
    end

    nexAtlas_saveCatalog(catalog, subjectDir);
    fprintf('[nexAtlas_reconcileCatalog] done — catalog has %d units with UnitMatch IDs.\n', catalog.n_units);
end


function catalog = mergeCatalogEntries(catalog, grp, uniq_ids)
% Merge groups of catalog rows that UnitMatch collapsed to the same global ID.
% Running means are re-weighted by n_sessions; templates use the entry with
% the highest n_sessions as the seed.

    n_uniq = numel(uniq_ids);
    sorterFields   = fieldnames(catalog.templates);
    nSessionFields = fieldnames(catalog.n_sessions);

    new_global_id    = uniq_ids(:);
    new_root_channel = zeros(n_uniq, 1);
    new_ch_centroid  = zeros(n_uniq, 1);
    new_templates    = struct();
    new_n_sessions   = struct();
    new_feat_data    = zeros(n_uniq, size(catalog.features.data, 2));
    new_feat_nobs    = zeros(n_uniq, 1);
    new_cell_type    = repmat("unclassified", n_uniq, 1);
    new_burst_frac   = zeros(n_uniq, 1);

    for sf = sorterFields',  new_templates.(sf{1})   = []; end
    for nf = nSessionFields', new_n_sessions.(nf{1}) = zeros(n_uniq, 1); end

    for g = 1:n_uniq
        rows = find(grp == g);
        % Use row with most sessions as the representative
        [~, best] = max(catalog.features.n_obs(rows));
        rep = rows(best);

        new_root_channel(g) = catalog.root_channel(rep);
        new_ch_centroid(g)  = catalog.ch_centroid(rep);
        new_cell_type(g)    = catalog.labels.cell_type(rep);

        % Merge features: weighted mean
        total_obs = sum(catalog.features.n_obs(rows));
        new_feat_nobs(g) = total_obs;
        if total_obs > 0
            w = catalog.features.n_obs(rows) / total_obs;
            new_feat_data(g, :) = sum(catalog.features.data(rows, :) .* w, 1);
        end
        new_burst_frac(g) = sum(catalog.labels.burst_frac(rows) .* ...
            catalog.features.n_obs(rows)) / max(total_obs, 1);

        % Merge templates: weighted mean per sorter
        for sf = sorterFields'
            fn = sf{1};
            T  = catalog.templates.(fn);
            if isempty(T) || size(T, 2) < max(rows), continue; end
            ns = zeros(numel(rows), 1);
            nfn = strrep(fn, 'template_', 'n_sessions_');
            if isfield(catalog.n_sessions, nfn) && numel(catalog.n_sessions.(nfn)) >= max(rows)
                ns = catalog.n_sessions.(nfn)(rows);
            end
            tot = sum(ns);
            if tot == 0
                merged_t = T(:, rep);
            else
                w = ns / tot;
                merged_t = T(:, rows) * w;
            end
            if isempty(new_templates.(fn))
                new_templates.(fn) = merged_t;
            else
                new_templates.(fn)(:, end+1) = merged_t;
            end
        end

        % Merge n_sessions per sorter
        for nf = nSessionFields'
            fn = nf{1};
            if numel(catalog.n_sessions.(fn)) >= max(rows)
                new_n_sessions.(fn)(g) = sum(catalog.n_sessions.(fn)(rows));
            end
        end
    end

    catalog.n_units      = n_uniq;
    catalog.global_id    = new_global_id;
    catalog.root_channel = new_root_channel;
    catalog.ch_centroid  = new_ch_centroid;
    catalog.templates    = new_templates;
    catalog.n_sessions   = new_n_sessions;
    catalog.features.data  = new_feat_data;
    catalog.features.n_obs = new_feat_nobs;
    catalog.labels.cell_type  = new_cell_type;
    catalog.labels.burst_frac = new_burst_frac;
end
