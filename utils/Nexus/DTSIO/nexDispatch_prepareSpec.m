function specPath = nexDispatch_prepareSpec(nexObj_ctg, mdlObj, spec)
% Resolve live MATLAB objects into a portable JSON dispatch spec.
% No live objects cross the boundary — only disk paths and plain values.
%
% Selection mirrors nexOp_compileSTAT exactly:
%   1. controlPanel.averagingSelection  → router-level rows (subject/date/phase)
%   2. nexObj_ctg.selectionBus          → categorical refinement within those rows
%
% Required spec fields:
%   dfID             : input data dfID (e.g. "lfp")
%   dmCfg.format     : "stack" | "batch" | "supervised"
%   dmCfg.labelID    : (supervised) dfID-style column, e.g. "sessionLabel--phase"
%   cvCfg.nFolds     : number of CV folds
%   cvCfg.nPermute   : number of permutations for null distribution
%   resultID         : key in nexObj_ctg.RESULTS on reload
%   resultsPath      : absolute path where agent writes results (.mat)
%   specPath         : absolute path to write the JSON spec

    nexon = nexObj_ctg.nexon;
    DTS   = nexon.console.BASE.DTS;

    assert(ismember('h5_path', DTS.Properties.VariableNames), ...
        'DTS must be disk-backed (h5_path column absent). Run nexus_exportDTS first.');

    % ── 1. Router selection (controlPanel.averagingSelection) ─────────────
    S_router  = nex_returnSelectionMask(nexon.console.BASE.controlPanel.averagingSelection);
    idxSel    = nex_applySelectionMask(DTS, S_router);   % logical, all DTS rows
    routerRows = find(idxSel);

    % ── 2. Categorical refinement (nexObj_ctg selection buses) ────────────
    S_cat   = nex_returnSelectionMask(nexObj_ctg.selectionBus.categories);
    S_items = nex_returnSelectionMask(nexObj_ctg.selectionBus.items);
    selMatch = true(numel(routerRows), 1);
    catFields = fieldnames(S_cat);
    for i = 1:numel(catFields)
        categoryID = S_cat.(catFields{i});
        if ~contains(categoryID, "ax") && ~strcmp(categoryID, "None")
            TF_cat   = dtsIO_readTF_category(nexon, categoryID, idxSel);
            selMatch = selMatch & ismember(TF_cat, S_items.(catFields{i}));
        end
    end
    finalRows = routerRows(selMatch);

    h5File  = char(DTS.h5_path(finalRows(1)));
    h5Roots = cellstr(DTS.h5_root(finalRows));

    % ── 3. Resolve label values (supervised only) ─────────────────────────
    labelValues = {};
    if strcmpi(spec.dmCfg.format, 'supervised')
        assert(isfield(spec.dmCfg, 'labelID') && ~isempty(spec.dmCfg.labelID), ...
            'dmCfg.labelID required for supervised format');
        % Build a logical mask for only finalRows within DTS
        idxFinal = false(height(DTS), 1);
        idxFinal(finalRows) = true;
        rawLabels   = dtsIO_readTF_category(nexon, spec.dmCfg.labelID, idxFinal);
        labelValues = cellstr(string(rawLabels));
    end

    % ── 4. Walk mdlObj → Predictor chain ──────────────────────────────────
    modelChain = {};
    node = mdlObj;
    while ~isempty(node)
        link.modelID  = char(node.modelID);
        link.fitPath  = char(node.fitPath);
        link.dmFormat = char(node.cfg.dmCfg.format);

        if strcmpi(node.cfg.dmCfg.format, 'supervised')
            % Predictor nodes: agent derives input shape from the embedding
            % link above — domain here is not yet populated and not needed.
            link.domain   = struct();
            link.dfID_target = char(node.dfID_target);
        else
            % Embedding nodes (SSM, PCA, ...): domain is the axis spec for
            % building X — only include if already populated.
            if ~isempty(node.domain) && ~isempty(node.domain.D1)
                link.domain.D1  = cellstr(string(node.domain.D1));
                link.domain.FTR = cellstr(string(node.domain.FTR));
            else
                link.domain = struct();
            end
            link.dfID_target = '';
        end

        modelChain{end+1} = link; %#ok<AGROW>
        if isprop(node,'Predictor') && ~isempty(node.Predictor) && ~isequal(node.Predictor,node)
            node = node.Predictor;
        else
            break;
        end
    end

    % ── 5. Assemble spec struct ────────────────────────────────────────────
    S.analysisType   = 'cvPermute';
    S.h5File         = h5File;
    S.trials         = h5Roots;
    S.labelValues    = labelValues;
    S.dfID           = char(spec.dfID);
    S.modelChain     = modelChain;
    S.dmCfg.format   = char(spec.dmCfg.format);
    S.dmCfg.labelID  = char(getfield_default(spec.dmCfg, 'labelID', ''));
    S.cvCfg.nFolds   = spec.cvCfg.nFolds;
    S.cvCfg.nPermute = spec.cvCfg.nPermute;
    S.resultID       = char(spec.resultID);
    S.resultsPath    = char(spec.resultsPath);

    % ── 6. Write JSON ──────────────────────────────────────────────────────
    specPath = char(spec.specPath);
    [parentDir,~,~] = fileparts(specPath);
    if ~isfolder(parentDir), mkdir(parentDir); end
    fid = fopen(specPath, 'w');
    fprintf(fid, '%s', jsonencode(S, 'PrettyPrint', true));
    fclose(fid);

    chainStr = strjoin(cellfun(@(l) l.modelID, modelChain, 'UniformOutput',false), '→');
    fprintf('[nexDispatch] spec written → %s\n', specPath);
    fprintf('  %d trials | chain: %s | dm: %s | %d folds × %d perms\n', ...
        numel(h5Roots), chainStr, S.dmCfg.format, spec.cvCfg.nFolds, spec.cvCfg.nPermute);
end

function v = getfield_default(s, field, default)
    if isfield(s, field), v = s.(field); else, v = default; end
end
