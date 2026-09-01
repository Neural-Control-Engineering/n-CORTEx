function nexAtlas_registerSession(subjectDir, sessionLabel, DF_templates, args)
% Register one session into the ephys atlas: update unit catalog + phase posterior.
%
% Called at extraction time (after sorting) while waveform templates are available.
% Asynchronous deferred features (fooof, rtPMTM) are added later via nexAtlas_updateSession.
%
%   subjectDir    fully-resolved subject directory
%   sessionLabel  DTS sessionLabel string — HDF5 session key; phase parsed from it
%                 Expected format: '..._phase--spontaneous_...' (standard DTS label)
%   DF_templates  spk_templates DF: df (n_wf × n_units), ax.unit, ax.chans, ax.wf
%
% Optional args fields:
%   fs            sampling rate Hz (default 30000)
%   DF_spatial    spk_spatial DF  — enables footprint_nch, peak_amp features
%   DF_isi        output of nexOp_ISIstats — appends firing_rate, cv_isi, burst_index
%   sorterTag     'KS' or 'RT' (default 'KS')
%   match_thresh  cosine similarity threshold for unit catalog matching (default 0.85)

    if nargin < 4 || isempty(args), args = struct(); end
    fs           = getf(args, 'fs',           30000);
    DF_spatial   = getf(args, 'DF_spatial',   []);
    DF_isi       = getf(args, 'DF_isi',       []);
    sorterTag    = getf(args, 'sorterTag',    'KS');
    match_thresh = getf(args, 'match_thresh', 0.85);

    % Parse phase directly from the sessionLabel
    phase = char(parseSessionLabel(sessionLabel, 'phase'));
    if isempty(phase)
        phase = 'unknown';
        warning('[nexAtlas_registerSession] no phase-- token in sessionLabel: %s', sessionLabel);
    end

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    fprintf('[nexAtlas_registerSession] %s / %s (phase: %s)\n', ...
        sessionLabel, sorterTag, phase);

    % ── Compute unit features ─────────────────────────────────────────────────
    feat_args.fs         = fs;
    feat_args.DF_spatial = DF_spatial;
    feat_args.DF_isi     = DF_isi;
    DF_features = nexOp_unitFeatures(DF_templates, feat_args);

    n_units = size(DF_features.df, 1);
    fprintf('  %d units  features: %s\n', n_units, strjoin(DF_features.ax.measure, ', '));

    % ── Re-registration guard ─────────────────────────────────────────────────
    % If already registered: delegate to writeSessionRecord (which has per-field
    % skip-if-exists guards) so any fields missing from the original registration
    % are patched automatically. Catalog update and Bayesian update are skipped
    % to prevent double-counting. Run nexAtlas_recomputePosteriors afterward.
    if isfile(atlasFile)
        try
            h5info(atlasFile, ['/sessions/' char(sessionLabel) '/phase']);
            writeSessionRecord(atlasFile, sessionLabel, phase, sorterTag, ...
                               nan(n_units,1), zeros(n_units,1), DF_features);
            fprintf('  already registered — patched missing fields.\n');
            fprintf('  run nexAtlas_recomputePosteriors to update posteriors.\n');
            return;
        catch
            % Not yet registered — fall through to full registration
        end
    end

    % ── Unit catalog: match + update ──────────────────────────────────────────
    catalog = nexAtlas_loadCatalog(subjectDir);

    [global_ids, match_conf] = nexAtlas_matchUnits( ...
        catalog, double(DF_templates.df), sorterTag, match_thresh);

    n_matched = sum(~isnan(global_ids));
    n_new     = sum(isnan(global_ids));
    fprintf('  catalog: %d matched  %d new\n', n_matched, n_new);

    % Assign new global IDs (max existing + sequential)
    next_id = catalog.n_units + 1;
    for u = 1:n_units
        if isnan(global_ids(u))
            global_ids(u) = next_id;
            next_id = next_id + 1;
        end
    end

    % Update catalog arrays for matched units (running mean of templates + features)
    catalog = updateCatalog(catalog, global_ids, match_conf, ...
                            DF_templates, DF_features, sorterTag);

    nexAtlas_saveCatalog(catalog, subjectDir);

    % ── Write session record ──────────────────────────────────────────────────
    writeSessionRecord(atlasFile, sessionLabel, phase, sorterTag, ...
                       global_ids, match_conf, DF_features);

    % ── Bayesian posterior update ─────────────────────────────────────────────
    nexAnalysis_ephysAtlas(subjectDir, sessionLabel, phase, DF_features);

    fprintf('[nexAtlas_registerSession] done — atlas updated\n');
end


% ── Catalog update ────────────────────────────────────────────────────────────

function catalog = updateCatalog(catalog, global_ids, match_conf, ...
                                  DF_templates, DF_features, sorterTag)

    waveforms  = double(DF_templates.df);     % (n_wf × n_units)
    root_chans = double(DF_templates.ax.chans);
    n_units    = numel(global_ids);
    tField     = ['template_' char(sorterTag)];
    nField     = ['n_sessions_' char(sorterTag)];

    for u = 1:n_units
        gid = global_ids(u);
        idx = find(catalog.global_id == gid, 1);

        if isempty(idx)
            % New unit — append to catalog
            catalog.n_units               = catalog.n_units + 1;
            catalog.global_id(end+1)      = gid;
            catalog.root_channel(end+1)   = root_chans(u);
            catalog.ch_centroid(end+1)    = root_chans(u);   % placeholder; depth lookup deferred
            if ~isfield(catalog.templates, tField) || isempty(catalog.templates.(tField))
                catalog.templates.(tField) = waveforms(:, u);
            else
                catalog.templates.(tField)(:, end+1) = waveforms(:, u);
            end
            if ~isfield(catalog.n_sessions, nField)
                catalog.n_sessions.(nField) = 1;
            else
                catalog.n_sessions.(nField)(end+1) = 1;
            end
            idx = catalog.n_units;
        else
            % Existing unit — running mean update of template
            % Guard: this sorter may not have processed this unit before
            if ~isfield(catalog.n_sessions, nField) || numel(catalog.n_sessions.(nField)) < idx
                n = 0;
            else
                n = catalog.n_sessions.(nField)(idx);
            end
            if n == 0 || ~isfield(catalog.templates, tField) || size(catalog.templates.(tField), 2) < idx
                catalog.templates.(tField)(:, idx) = waveforms(:, u);
            else
                catalog.templates.(tField)(:, idx) = ...
                    (catalog.templates.(tField)(:, idx) * n + waveforms(:, u)) / (n + 1);
            end
            if ~isfield(catalog.n_sessions, nField)
                catalog.n_sessions.(nField) = zeros(catalog.n_units, 1);
            end
            catalog.n_sessions.(nField)(idx) = n + 1;
        end

        % Running mean update of waveform features
        feat_row = double(DF_features.df(u, :));
        if size(catalog.features.data, 1) < idx || size(catalog.features.data, 2) == 0
            % First feature entry — initialise
            n_feat = numel(feat_row);
            if size(catalog.features.data, 2) == 0
                catalog.features.data  = NaN(catalog.n_units, n_feat);
                catalog.features.n_obs = zeros(catalog.n_units, 1);
                catalog.features.names = DF_features.ax.measure;
            else
                % Extend rows to accommodate new unit
                catalog.features.data(end+1, :)  = NaN(1, n_feat);
                catalog.features.n_obs(end+1)     = 0;
            end
        end
        n_obs = catalog.features.n_obs(idx);
        old   = catalog.features.data(idx, :);
        valid = isfinite(feat_row) & isfinite(old);
        catalog.features.data(idx, valid) = ...
            (old(valid) * n_obs + feat_row(valid)) / (n_obs + 1);
        catalog.features.data(idx, ~isfinite(old) & isfinite(feat_row)) = ...
            feat_row(~isfinite(old) & isfinite(feat_row));
        catalog.features.n_obs(idx) = n_obs + 1;

        % Cell-type label: majority vote (new label wins ties)
        new_ct = DF_features.labels.cell_type(u);
        if idx > numel(catalog.labels.cell_type)
            catalog.labels.cell_type(idx)  = new_ct;
            catalog.labels.burst_frac(idx) = double(DF_features.labels.burst_mode(u));
        else
            old_ct  = catalog.labels.cell_type(idx);
            old_bf  = catalog.labels.burst_frac(idx);
            n_obs_l = catalog.features.n_obs(idx);
            % Keep majority: if new label is FSU/RSU prefer it over unclassified
            if new_ct ~= "unclassified"
                catalog.labels.cell_type(idx) = new_ct;
            elseif old_ct == "unclassified"
                catalog.labels.cell_type(idx) = new_ct;
            end
            catalog.labels.burst_frac(idx) = ...
                (old_bf * (n_obs_l - 1) + double(DF_features.labels.burst_mode(u))) / n_obs_l;
        end
    end
end


% ── Session record writer ─────────────────────────────────────────────────────

function writeSessionRecord(atlasFile, sessionLabel, phase, sorterTag, ...
                             global_ids, match_conf, DF_features)

    basePath = ['/sessions/' char(sessionLabel) '/'];

    % Phase and sorter tags — write once; skip if session already registered
    exists = false;
    try, h5info(atlasFile, [basePath 'phase']); exists = true; catch, end

    if ~exists
        % String scalars via overwrite helper (handles create + write)
        nexAtlas_h5overwrite(atlasFile, [basePath 'phase'],      {char(phase)});
        nexAtlas_h5overwrite(atlasFile, [basePath 'sorter_tag'], {char(sorterTag)});
    end

    % Unit registration arrays — immutable once written for this sorter.
    % cosine_global_ids preserves the cosine-similarity IDs that link to the
    % catalog even after nexAtlas_runUnitMatch overwrites global_ids with
    % UnitMatch IDs — required by nexAtlas_reconcileCatalog.
    sortPath = [basePath char(sorterTag) '/'];
    fields   = {'global_ids', 'cosine_global_ids', 'match_conf', 'local_ids', 'root_ch'};
    data     = {double(global_ids(:)), double(global_ids(:)), double(match_conf(:)), ...
                double(DF_features.ax.unit(:)), double(DF_features.ax.chans(:))};
    for fi = 1:numel(fields)
        path = [sortPath fields{fi}];
        try, h5info(atlasFile, path); catch
            h5create(atlasFile, path, size(data{fi}), 'Datatype', 'double');
            h5write(atlasFile,  path, data{fi});
        end
    end

    % Immediate features (overwrite — may be augmented later by nexAtlas_updateSession)
    nexAtlas_h5overwrite(atlasFile, [basePath 'features_immediate'], ...
        double(DF_features.df));
    nexAtlas_h5overwrite(atlasFile, [basePath 'feature_names'], ...
        DF_features.ax.measure);
    nexAtlas_h5overwrite(atlasFile, [basePath 'contributed'], uint8(0));
end


function v = getf(s, field, default)
    if isfield(s, field), v = s.(field); else, v = default; end
end
