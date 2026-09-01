function nexAtlas_saveCatalog(catalog, subjectDir)
% Write the unit catalog into /units/ in ephys_atlas.h5.
% Uses delete-and-recreate for catalog datasets so the catalog can grow each session.
% Session records are written once and never overwritten.
%
% Catalog struct expected fields (beyond core arrays):
%   features.data   (n_units × n_features) — running-mean waveform features
%   features.n_obs  (n_units,)             — sessions contributing per unit
%   features.names  (1 × n_features) str   — feature names (from nexOp_unitFeatures)
%   labels.cell_type  (n_units,) str       — "RSU"/"FSU"/"unclassified" (majority vote)
%   labels.burst_frac (n_units,) double    — fraction of sessions with burst_mode flag

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');

    % Core scalar and per-unit arrays — overwrite each time
    nexAtlas_h5overwrite(atlasFile, '/units/catalog/n_units',      double(catalog.n_units));
    nexAtlas_h5overwrite(atlasFile, '/units/catalog/global_id',    double(catalog.global_id(:)));
    nexAtlas_h5overwrite(atlasFile, '/units/catalog/root_channel', double(catalog.root_channel(:)));
    nexAtlas_h5overwrite(atlasFile, '/units/catalog/ch_centroid',  double(catalog.ch_centroid(:)));

    % Per-sorter template arrays and session counts
    sorterFields = fieldnames(catalog.templates);
    for i = 1:numel(sorterFields)
        name = sorterFields{i};                  % e.g. 'template_KS'
        nexAtlas_h5overwrite(atlasFile, ['/units/catalog/' name], ...
            double(catalog.templates.(name)));
    end
    countFields = fieldnames(catalog.n_sessions);
    for i = 1:numel(countFields)
        name = countFields{i};                   % e.g. 'n_sessions_KS'
        nexAtlas_h5overwrite(atlasFile, ['/units/catalog/' name], ...
            double(catalog.n_sessions.(name)(:)));
    end

    % Waveform features — overwrite (catalog grows each session)
    if isfield(catalog, 'features') && ~isempty(catalog.features.data)
        nexAtlas_h5overwrite(atlasFile, '/units/catalog/features/data',  double(catalog.features.data));
        nexAtlas_h5overwrite(atlasFile, '/units/catalog/features/n_obs', double(catalog.features.n_obs(:)));
        nexAtlas_h5overwrite(atlasFile, '/units/catalog/features/names', catalog.features.names);
    end

    % Cell-type labels — overwrite
    if isfield(catalog, 'labels') && ~isempty(catalog.labels.cell_type)
        nexAtlas_h5overwrite(atlasFile, '/units/catalog/labels/cell_type',  catalog.labels.cell_type);
        nexAtlas_h5overwrite(atlasFile, '/units/catalog/labels/burst_frac', double(catalog.labels.burst_frac(:)));
    end

    % Per-session records are written directly by writeSessionRecord in
    % nexAtlas_registerSession (with ~exists guards) and are not round-tripped
    % through the MATLAB catalog struct — session labels exceed MATLAB's 63-char
    % fieldname limit and the HDF5 is the authoritative store.
end
