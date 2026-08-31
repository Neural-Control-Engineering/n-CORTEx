function [global_ids, match_conf] = nexAtlas_matchUnits(catalog, templates_new, sorterTag, threshold)
% Match new unit templates against the existing catalog using cosine similarity.
%
%   templates_new  (n_wf × n_new) — new unit waveforms (root-channel)
%   sorterTag      string — 'KS' or 'RT' (DTS prefix without trailing underscore)
%   threshold      scalar — minimum cosine similarity to declare a match (default 0.85)
%
%   global_ids   (n_new,1) — catalog global_id for matched units; NaN for new units
%   match_conf   (n_new,1) — cosine similarity score (0 for unmatched)

    if nargin < 4, threshold = 0.85; end

    n_new      = size(templates_new, 2);
    global_ids = NaN(n_new, 1);
    match_conf = zeros(n_new, 1);

    if catalog.n_units == 0, return; end

    catField = ['template_' char(sorterTag)];
    if ~isfield(catalog.templates, catField) || isempty(catalog.templates.(catField))
        return;   % no templates from this sorter yet — all new
    end

    cat_T = double(catalog.templates.(catField));   % (n_wf × n_cat)
    n_cat = size(cat_T, 2);

    % Cosine similarity matrix (n_new × n_cat)
    nNew = vecnorm(templates_new, 2, 1); nNew(nNew == 0) = 1;
    nCat = vecnorm(cat_T,         2, 1); nCat(nCat == 0) = 1;
    sim  = (templates_new ./ nNew)' * (cat_T ./ nCat);   % (n_new × n_cat)

    % Optimal bipartite matching (MATLAB built-in, R2020a+)
    % matchpairs minimises cost; cost = 1 - sim; unmatch penalty = 1 - threshold
    [M, ~] = matchpairs(1 - sim, 1 - threshold);   % M: (k×2) [new_idx, cat_idx]

    for i = 1:size(M, 1)
        ni = M(i,1);  ci = M(i,2);
        sc = sim(ni, ci);
        if sc >= threshold
            global_ids(ni) = catalog.global_id(ci);
            match_conf(ni) = sc;
        end
    end
end
