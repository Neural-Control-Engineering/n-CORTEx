function nexOp_reportSTAT_test(nexObj, fcn, compareVars, groupVars, k, resID)
% Apply a comparative function across k-wise trial-paired combinations of
% compareVars levels, stratified by groupVars, storing results in nexObj.RESULTS.
%
% nexObj      — nexObject (categorical, or any nexObject with a ctg partner)
% fcn         — @(DF_1, ..., DF_k) → result struct with at least a df field
% compareVars — category column names whose levels become comparison elements
% groupVars   — category column names that stratify comparisons (→ Pointer axes)
% k           — combination arity (default 2 = pairwise)
% resID       — string key under nexObj.RESULTS

    if nargin < 5 || isempty(k), k = 2; end
    compareVars = string(compareVars(:))';
    groupVars   = string(groupVars(:))';
    groupVars   = groupVars(groupVars ~= "");

    % ── Step 1: Compile label table ───────────────────────────────────────
    % Y has one row per trial, columns = category labels + Y.index (DTS row).
    % idxSel is the logical DTS filter (controlPanel + categorical selection).
    categories  = union(compareVars, groupVars, "stable");
    [Y, idxSel] = nexOp_compileLabels(nexObj, cellstr(categories));
    if isempty(Y) || height(Y) == 0, return; end

    % ── Step 2: Sort and enumerate ────────────────────────────────────────
    % Y_enum = Y sorted by [groupVars, compareVars] with trialNumber added.
    % trialNumber restarts at 1 within each (group × item) cell → [1,2,3,1,2,3,...]
    % G carries byGroup, byItem, combos{g}, labels{g} for loop navigation.
    [Y_enum, G] = nexOp_enumerateCategories(Y, compareVars, groupVars, k);
    if G.nGroups == 0, return; end

    % ── Step 3: Axis pooling config ───────────────────────────────────────
    pm  = nexObj.pMap;
    ptr = nexObj.DF_postOp.ptr;

    % ── Step 4: Nested loop: groups → k-combinations → paired trials ──────
    result_rows = {};

    for g = 1:G.nGroups
        mask_g = G.byGroup == g;   % rows in Y_enum belonging to this stratum
        combos = G.combos{g};      % nCombos × k matrix of item IDs
        labels = G.labels{g};      % nCombos × 1 comparison label strings
        if isempty(combos), continue; end

        for c = 1:size(combos, 1)

            % ── Find shared trial numbers across all k items ───────────────
            % Each item may have different trial counts; intersection ensures
            % we only compare trials that exist in every element of the combo.
            sharedTrials = [];
            for ki = 1:k
                mask_ki = mask_g & G.byItem == combos(c, ki);
                tNums   = Y_enum.trialNumber(mask_ki);
                if ki == 1
                    sharedTrials = tNums;                          % seed with item 1
                else
                    sharedTrials = intersect(sharedTrials, tNums); % narrow to shared
                end
            end
            if isempty(sharedTrials), continue; end

            % ── Trial loop: pair trial j across all k items ───────────────
            for j = 1:numel(sharedTrials)
                t       = sharedTrials(j);   % current shared trial number
                DF_args = cell(1, k);
                ok      = true;
                try
                    for ki = 1:k
                        % Single Y_enum row for (group g, item ki, trial t)
                        row = find(mask_g & G.byItem == combos(c,ki) & Y_enum.trialNumber == t, 1);
                        % Y_enum.index carries the DTS row (stamped by compileLabels)
                        idxVec = false(numel(idxSel), 1);
                        idxVec(Y_enum.index(row)) = true;
                        % Read single trial DF from DTS and pool axes
                        TF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, idxVec);
                        if ~isempty(pm)
                            TF = cellfun(@(DF) nexOp_poolAxes(pm, DF, ptr), TF, "UniformOutput", false);
                        end
                        DF_args{ki} = TF{1};   % unpack from cell — one trial per ki
                    end
                    % Call comparison function with k trial-paired DFs
                    result = fcn(DF_args{:});
                catch e
                    disp(getReport(e));
                    ok = false;
                end
                if ~ok, continue; end

                % ── Build result row ──────────────────────────────────────
                row_s  = struct();
                repRow = find(mask_g, 1);
                % groupVar values → become Pointer axes in RESULTS
                for v = 1:numel(groupVars)
                    row_s.(char(groupVars(v))) = string(Y_enum.(char(groupVars(v)))(repRow));
                end
                row_s.comparison  = labels(c);   % → VW in RESULTS
                row_s.trialNumber = t;            % retained for trial-level inspection
                % result fields (df, ax, ptr, or whatever fcn returns)
                resFlds = fieldnames(result);
                for f = 1:numel(resFlds)
                    row_s.(resFlds{f}) = result.(resFlds{f});
                end
                result_rows{end+1} = row_s; %#ok<AGROW>
            end
        end
    end

    if isempty(result_rows), return; end

    % ── Step 5: Assemble RESULTS table ───────────────────────────────────
    % AsArray=true prevents struct2table from expanding array-valued fields
    % into multiple rows. Result fields (df, ax, etc.) are then wrapped into
    % cell columns so each row of T holds one result array.
    T = struct2table(vertcat(result_rows{:}), "AsArray", true);
    resFlds = string(fieldnames(result));
    for f = 1:numel(resFlds)
        fld = char(resFlds(f));
        if ~iscell(T.(fld))
            T.(fld) = num2cell(T.(fld), 2);
        end
    end

    % ── Step 6: Store result and refresh SRC bus ──────────────────────────
    % refreshSRC updates the SRC listbox to include the new resID entry.
    nexObj.RESULTS.(char(resID)) = T;
    if ismethod(nexObj, 'refreshSRC')
        nexObj.refreshSRC();
    end
end
