function nexAtlas_recomputePosteriors(subjectDir)
% Re-evaluate all registered sessions against the current /reference/ Gaussians
% and rebuild the canonical posterior from scratch.
%
% Call this after tuning reference values (via nexAtlas_queryIBL or manual h5 edit)
% to propagate the updated reference into the working regionMAP.
% No re-extraction needed — session features are read from the atlas HDF5.
%
% Workflow:
%   1. nexAtlas_setFeatureWeights  (tune weights)
%   2. edit /reference/ (via nexAtlas_queryIBL or h5py script)
%   3. nexAtlas_recomputePosteriors(subjDir)  <- this function
%   Result: canonical posterior reflects new reference + all registered sessions.

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    if ~isfile(atlasFile)
        error('nexAtlas_recomputePosteriors:noAtlas', 'ephys_atlas.h5 not found: %s', atlasFile);
    end

    % ── Reset all per-phase posteriors to NTE prior ───────────────────────────
    prior = h5read(atlasFile, '/prior/P');
    try
        phasesInfo = h5info(atlasFile, '/posteriors');
        for i = 1:numel(phasesInfo.Groups)
            pPath = phasesInfo.Groups(i).Name;
            phase = pPath(max(strfind(pPath, '/'))+1:end);
            if strcmp(phase, 'canonical'), continue; end
            nexAtlas_h5overwrite(atlasFile, [pPath '/posterior'],  prior);
            nexAtlas_h5overwrite(atlasFile, [pPath '/n_sessions'], double(0));
            fprintf('[nexAtlas_recomputePosteriors] reset phase: %s\n', phase);
        end
    catch e
        fprintf('[nexAtlas_recomputePosteriors] could not reset posteriors: %s\n', e.message);
    end

    % ── Replay all registered sessions ───────────────────────────────────────
    try
        sessInfo = h5info(atlasFile, '/sessions');
    catch
        fprintf('[nexAtlas_recomputePosteriors] no sessions registered yet.\n');
        return;
    end

    n_ok   = 0;
    n_skip = 0;

    for i = 1:numel(sessInfo.Groups)
        sessPath = sessInfo.Groups(i).Name;
        fullKey  = sessPath(max(strfind(sessPath, '/'))+1:end);

        try
            phase      = char(h5read(atlasFile, [sessPath '/phase']));
            feat_data  = h5read(atlasFile, [sessPath '/features_immediate']);  % (n_units × n_feat)
            feat_names = string(h5read(atlasFile, [sessPath '/feature_names']));

            % Recover unit-to-channel mapping — stored per sorter; take first available
            root_ch = [];
            sorterInfo = h5info(atlasFile, sessPath);
            for g = 1:numel(sorterInfo.Groups)
                sortPath = sorterInfo.Groups(g).Name;
                try
                    root_ch = double(h5read(atlasFile, [sortPath '/root_ch']));
                    break;
                catch
                end
            end

            if isempty(root_ch)
                fprintf('[nexAtlas_recomputePosteriors] skipped %s — no root_ch stored\n', fullKey);
                n_skip = n_skip + 1;
                continue;
            end

            % Reconstruct DF_features from stored data
            DF.df          = feat_data;          % (n_units × n_feat)
            DF.ax.chans    = root_ch(:);
            DF.ax.measure  = feat_names(:)';
            DF.ax.unit     = (1:numel(root_ch))';

            % Mark as not-yet-contributed so nexAnalysis_ephysAtlas re-runs cleanly
            try
                nexAtlas_h5overwrite(atlasFile, [sessPath '/contributed'], uint8(0));
            catch
            end

            nexAnalysis_ephysAtlas(subjectDir, fullKey, phase, DF);
            n_ok = n_ok + 1;

        catch e
            fprintf('[nexAtlas_recomputePosteriors] skipped %s: %s\n', fullKey, e.message);
            n_skip = n_skip + 1;
        end
    end

    % ── Re-merge canonical ────────────────────────────────────────────────────
    nexAtlas_mergeCanonical(atlasFile);

    fprintf('[nexAtlas_recomputePosteriors] done — %d replayed, %d skipped.\n', n_ok, n_skip);
end
