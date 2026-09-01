function nexAtlas_setFeatureWeights(subjectDir, weights)
% Write per-feature likelihood weights into /config/feature_weights/ in ephys_atlas.h5.
% Weights in [0,1]: 1.0 = full contribution, 0.0 = excluded, 0.2 = heavily downweighted.
%
% weights   struct with fieldnames matching nexOp_unitFeatures output measure names.
%           Unspecified features default to 1.0 at inference time.
%
% Example — downweight firing rate, keep PTD and CV-ISI at full strength:
%   nexAtlas_setFeatureWeights(subjDir, struct('firing_rate', 0.15))
%
% Example — also moderately downweight burst_index (condition-sensitive):
%   nexAtlas_setFeatureWeights(subjDir, struct('firing_rate', 0.15, 'burst_index', 0.4))

    atlasFile = fullfile(subjectDir, 'npxls', 'ephys_atlas.h5');
    if ~isfile(atlasFile)
        error('nexAtlas_setFeatureWeights:noAtlas', ...
            'ephys_atlas.h5 not found — run nexAtlas_createAtlas first.');
    end

    names   = string(fieldnames(weights));
    vals    = cellfun(@(f) weights.(f), fieldnames(weights));

    if any(vals < 0 | vals > 1)
        error('nexAtlas_setFeatureWeights:range', 'All weights must be in [0, 1].');
    end

    nexAtlas_h5overwrite(atlasFile, '/config/feature_weights/names',   names);
    nexAtlas_h5overwrite(atlasFile, '/config/feature_weights/weights', double(vals(:)));

    fprintf('[nexAtlas_setFeatureWeights] written to %s\n', atlasFile);
    for i = 1:numel(names)
        fprintf('  %-20s  %.2f\n', names(i), vals(i));
    end
end
