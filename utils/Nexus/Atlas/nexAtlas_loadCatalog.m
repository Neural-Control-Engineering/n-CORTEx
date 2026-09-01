function catalog = nexAtlas_loadCatalog(subjectDir)
% Load the unit catalog from /units/catalog/ in ephys_atlas.h5.
% Returns an empty catalog struct if the file or catalog group doesn't exist yet.
%
% Catalog fields:
%   n_units          scalar  — current number of tracked units
%   global_id        (n,1)   — unique cross-session unit IDs
%   root_channel     (n,1)   — Neuropixels channel index per unit
%   ch_centroid      (n,1)   — µm from probe tip (running mean)
%   templates        struct  — per-sorter running-mean waveforms: template_KS, template_RT, …
%   n_sessions       struct  — per-sorter session count:          n_sessions_KS, n_sessions_RT, …
%   features.data   (n×f)    — running-mean waveform feature matrix (from nexOp_unitFeatures)
%   features.n_obs  (n,1)    — sessions contributing per unit (for proper running-mean update)
%   features.names  (1×f) str — feature names matching ax.measure in nexOp_unitFeatures output
%   labels.cell_type  (n,1) str — "RSU"/"FSU"/"unclassified" (majority vote across sessions)
%   labels.burst_frac (n,1)  — fraction of sessions where burst_mode was flagged
%   sessions         struct  — per-session registration records

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');

    if ~isfile(atlasFile)
        catalog = emptyUnitCatalog();
        return;
    end

    % Check /units/catalog exists
    try
        h5info(atlasFile, '/units/catalog');
    catch
        catalog = emptyUnitCatalog();
        return;
    end

    c = struct();
    c.n_units      = double(h5read(atlasFile, '/units/catalog/n_units'));
    c.global_id    = h5read(atlasFile, '/units/catalog/global_id');
    c.root_channel = h5read(atlasFile, '/units/catalog/root_channel');
    c.ch_centroid  = h5read(atlasFile, '/units/catalog/ch_centroid');

    % Per-sorter template stores (may not exist yet on first registration)
    c.templates  = struct();
    c.n_sessions = struct();
    try
        catInfo = h5info(atlasFile, '/units/catalog');
        for i = 1:numel(catInfo.Datasets)
            name = catInfo.Datasets(i).Name;
            if startsWith(name, 'template_')
                c.templates.(name) = h5read(atlasFile, ['/units/catalog/' name]);
            elseif startsWith(name, 'n_sessions_')
                c.n_sessions.(name) = h5read(atlasFile, ['/units/catalog/' name]);
            end
        end
    catch
    end

    % Waveform features
    try
        c.features.data  = h5read(atlasFile, '/units/catalog/features/data');
        c.features.n_obs = h5read(atlasFile, '/units/catalog/features/n_obs');
        c.features.names = string(h5read(atlasFile, '/units/catalog/features/names'))';
    catch
        c.features = emptyFeatures();
    end

    % Cell-type labels
    try
        c.labels.cell_type  = string(h5read(atlasFile, '/units/catalog/labels/cell_type'));
        c.labels.burst_frac = h5read(atlasFile, '/units/catalog/labels/burst_frac');
    catch
        c.labels = emptyLabels();
    end

    % Session records are written once by writeSessionRecord (nexAtlas_registerSession)
    % directly into /units/sessions/<label>/ and are never re-read into MATLAB structs
    % (session labels exceed MATLAB's 63-char fieldname limit).
    % Query them directly from HDF5 when needed rather than caching here.
    c.sessions = struct();

    catalog = c;
end

function c = emptyUnitCatalog()
    c.n_units      = 0;
    c.global_id    = zeros(0,1,'double');
    c.root_channel = zeros(0,1,'double');
    c.ch_centroid  = zeros(0,1,'double');
    c.templates    = struct();
    c.n_sessions   = struct();
    c.features     = emptyFeatures();
    c.labels       = emptyLabels();
    c.sessions     = struct();
end

function f = emptyFeatures()
    f.data  = zeros(0,0,'double');
    f.n_obs = zeros(0,1,'double');
    f.names = string.empty(1,0);
end

function L = emptyLabels()
    L.cell_type  = string.empty(0,1);
    L.burst_frac = zeros(0,1,'double');
end
