function nexAtlas_mergeCanonical(atlasFile)
% Merge eligible phase posteriors into /posteriors/canonical/.
%
% Eligibility: phase must be listed in /config/canonical_eligible_phases
%              AND have n_sessions > 0.
% Merge: weighted average of eligible posteriors, weights = n_sessions per phase.
%
% Called automatically at the end of nexAnalysis_ephysAtlas.
% Can also be called manually after promoting a phase to the eligible list.

    % Load eligible phase list (stored in atlas; default if absent)
    try
        eligible = lower(string(h5read(atlasFile, '/config/canonical_eligible_phases')));
    catch
        eligible = ["spontaneous", "baseline"];
    end

    % Collect eligible phase posteriors
    posts    = {};
    weights  = [];
    included = string.empty(1, 0);

    for i = 1:numel(eligible)
        phase     = char(eligible(i));
        phasePath = ['/posteriors/' phase];
        try
            n_sess = double(h5read(atlasFile, [phasePath '/n_sessions']));
            if n_sess < 1, continue; end
            P = h5read(atlasFile, [phasePath '/posterior']);
            posts{end+1}   = P;
            weights(end+1) = n_sess;
            included(end+1) = string(phase);
        catch
        end
    end

    if isempty(posts)
        return;
    end

    % Weighted average; re-normalise rows for floating-point cleanliness
    w = weights / sum(weights);
    canonical = zeros(size(posts{1}));
    for i = 1:numel(posts)
        canonical = canonical + w(i) * posts{i};
    end
    canonical = canonical ./ sum(canonical, 2);

    nexAtlas_h5overwrite(atlasFile, '/posteriors/canonical/posterior',       canonical);
    nexAtlas_h5overwrite(atlasFile, '/posteriors/canonical/phases_included', included);
    nexAtlas_h5overwrite(atlasFile, '/posteriors/canonical/last_updated', ...
        {char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'))});
end
