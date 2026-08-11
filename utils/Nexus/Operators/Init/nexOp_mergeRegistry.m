function nexOp_mergeRegistry(nexon)
% Reconcile a cached registry with the CURRENT DTS.
%
%   nexOp_mergeRegistry(nexon)
%
% startNexus loads a cached registry on a cache hit and never re-initializes,
% so subjects/categories added to the DTS after the cache was written never
% appear (e.g. a new cohort in the subject dropdown). This upserts: it
% re-runs nexInit_registry (which re-enumerates categories from the live DTS
% and picks up the new items) and then RESTORES the previously cached LUT
% colors and per-subject region maps, so existing subjects keep their look and
% only genuinely new labels get freshly generated colors.
%
% Idempotent — safe to run on every launch after loadRegistry.

    reg0 = nexon.console.BASE.registry;
    if isempty(reg0) || ~isstruct(reg0)
        % No usable cache — a plain init from the DTS is the merge.
        nexInit_registry(nexon);
        return;
    end

    % Snapshot the state we want to preserve (colors + loaded region maps)
    % BEFORE nexInit_registry regenerates them.
    savedLUT  = struct();
    if isfield(reg0, 'LUT')  && isstruct(reg0.LUT),  savedLUT  = reg0.LUT;  end
    savedSUBJ = struct();
    if isfield(reg0, 'SUBJ') && isstruct(reg0.SUBJ), savedSUBJ = reg0.SUBJ; end

    % Rebuild categories / LUTs / SUBJ from the live DTS (picks up new items).
    nexInit_registry(nexon);
    reg = nexon.console.BASE.registry;

    % Restore cached colors for labels that already had one; new labels keep the
    % freshly generated colors from the rebuild.
    if isfield(reg, 'LUT') && isstruct(reg.LUT)
        lutKeys = fieldnames(reg.LUT);
        for i = 1:numel(lutKeys)
            k = lutKeys{i};
            if ~isfield(savedLUT, k), continue; end
            newLut = reg.LUT.(k);
            oldLut = savedLUT.(k);
            if ~istable(newLut) || ~istable(oldLut), continue; end
            if ~all(ismember({'label','color'}, newLut.Properties.VariableNames)) || ...
               ~all(ismember({'label','color'}, oldLut.Properties.VariableNames))
                continue;
            end
            [tf, loc] = ismember(string(newLut.label), string(oldLut.label));
            if any(tf)
                newLut.color(tf) = oldLut.color(loc(tf));   % keep existing colors
            end
            reg.LUT.(k) = newLut;
        end
    end

    % Preserve already-loaded region maps (avoids re-reading from disk and keeps
    % maps for subjects whose files may no longer resolve this session).
    if ~isfield(reg, 'SUBJ') || ~isstruct(reg.SUBJ), reg.SUBJ = struct(); end
    subjKeys = fieldnames(savedSUBJ);
    for i = 1:numel(subjKeys)
        reg.SUBJ.(subjKeys{i}) = savedSUBJ.(subjKeys{i});
    end

    nexon.console.BASE.registry = reg;
end
