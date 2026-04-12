function [Y_sorted, G] = nexOp_enumerateCategories(Y, compareVars, groupVars, k)
% Sort Y by [groupVars, compareVars] and enumerate k-combinations of
% compareVar levels within each groupVar stratum.
%
% Adds one column to Y_sorted:
%   trialNumber — within-(groupVars × compareVars) trial counter; restarts at
%                 1 for each unique combination → [1,2,3,1,2,3,...] pattern
%
% Output
%   Y_sorted      — Y sorted by [groupVars, compareVars] with trialNumber added
%   G.byGroup     — per-row group ID (from groupVars); drives outer loop
%   G.byItem      — per-row item ID within each group (from compareVars)
%   G.combos{g}   — nCombos × k matrix of itemNum values for group g
%   G.labels{g}   — nCombos × 1 comparison label strings for group g
%   G.nGroups     — total number of strata

    if nargin < 4 || isempty(k),         k = 2;          end
    if nargin < 3 || isempty(groupVars), groupVars = []; end
    compareVars = string(strrep(compareVars, "--", "_"))';
    groupVars   = string(strrep(groupVars,   "--", "_"))';
    groupVars   = groupVars(groupVars ~= "");

    % ── Sort by [groupVars, compareVars] ──────────────────────────────────
    sortCols = [groupVars, compareVars];
    sortCols = sortCols(ismember(sortCols, string(Y.Properties.VariableNames)));
    if ~isempty(sortCols)
        Y_sorted = sortrows(Y, cellstr(sortCols));
    else
        Y_sorted = Y;
    end
    nY = height(Y_sorted);

    % ── grpNum: sequential group ID from groupVars ────────────────────────
    if isempty(groupVars)
        G_group = ones(nY, 1);
        nGroups = 1;
    else
        G_group = findgroups(Y_sorted(:, cellstr(groupVars)));
        nGroups = max(G_group);
    end

    % ── itemNum: unique item ID within each group from compareVars ───────
    G_item = zeros(nY, 1);
    for g = 1:nGroups
        mask_g = G_group == g;
        G_item(mask_g) = findgroups(Y_sorted(mask_g, cellstr(compareVars)));
    end

    % ── trialNum: within-(group × item) trial counter ─────────────────────
    % Groups by the full [groupVars + compareVars] combination, then numbers
    % trials sequentially within each cell → [1,2,3,1,2,3,...] pattern.
    G_full    = findgroups(Y_sorted(:, cellstr([groupVars, compareVars])));
    trialNums = splitapply(@(x) {(1:numel(x))'}, G_full, G_full);
    Y_sorted.trialNumber = cat(1, trialNums{:});

    % ── k-combinations and labels per group ──────────────────────────────
    G_combos = cell(nGroups, 1);
    G_labels = cell(nGroups, 1);

    for g = 1:nGroups
        mask_g  = G_group == g;
        n_items = max(G_item(mask_g));

        if n_items < k
            G_combos{g} = zeros(0, k);
            G_labels{g} = strings(0, 1);
            continue;
        end

        local_combos = nchoosek(1:n_items, k);   % itemNum values
        G_combos{g}  = local_combos;

        nCombos = size(local_combos, 1);
        labels  = strings(nCombos, 1);
        for c = 1:nCombos
            parts = strings(1, k);
            for ki = 1:k
                itemRow = find(G_item == local_combos(c, ki) & mask_g, 1);
                valParts = strings(1, numel(compareVars));
                for vi = 1:numel(compareVars)
                    raw = Y_sorted.(char(compareVars(vi)))(itemRow);
                    if iscell(raw), raw = raw{1}; end
                    valParts(vi) = string(raw);
                end
                parts(ki) = strjoin(valParts, "·");
            end
            labels(c) = strjoin(parts, "_vs_");
        end
        G_labels{g} = labels;
    end

    % ── Pack G ────────────────────────────────────────────────────────────
    G.byGroup = G_group;
    G.byItem  = G_item;
    G.combos  = G_combos;
    G.labels  = G_labels;
    G.nGroups = nGroups;
end
