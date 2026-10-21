function T = build_bandPowerRegionTable(mdlObj, forceRecompile, gridCols)
% build_bandPowerRegionTable  Long-format table for the fitlme hierarchy,
% one row per (trial, <gridCols>, band), built directly off an
% already-configured mdlObj_lda (headed Figure or not — never touched
% here).
%
% Reuses the EXACT band definitions mdlObj's own pMap.f pooling used for
% the LDA fit (no separately-hardcoded Hz ranges) — compileSTAT() has
% already mean-pooled 'f' into whatever bands pMap.f is configured with,
% so stage 1 (LDA decoding) and stage 2 (this table/fitlme) can never
% drift onto different band definitions.
%
% gridCols (default {'chans','t'}) are read straight off nexOp_stackSTAT's
% own G table — it already expands EVERY ax field except whichever owns
% the F dimension into its own G column (STAT.ax(i).chans, STAT.ax(i).t,
% etc.), independent of domain.REG entirely. This is the same per-trial
% axis data the LDA's own SWP bus sweeps over (chans/t selected there) —
% treating them as grid dimensions here, exactly like band, means every
% cell ends up with exactly one row per trial: no non-independence to
% model around, unlike collapsing to one "region" column previously did
% (which silently flattened chans AND t together into repeated-measures
% rows sharing one subject+condition label — the ~859-level/98268-row
% inflation a live run surfaced).
%
%   mdlObj         : an mdlObj_lda (or any mdlObj) with dfID_source,
%                    dfID_target (target-variable dropdown selection),
%                    and pMap already configured exactly as for its own
%                    LDA fit.
%   forceRecompile : optional, default false. mdlObj.compileSTAT() is
%                    skipped and mdlObj.STAT is reused as-is whenever it's
%                    already populated (nonempty, matching height to its
%                    own idxSel isn't re-verified here — caller's
%                    responsibility if selections changed since the last
%                    compile) — recompiling re-walks nexOp_compileTF's
%                    pre-pooling intermediates a second time, which is
%                    memory you don't want to spend twice when already
%                    near a hardware ceiling. Pass true only if you've
%                    changed categories/items since mdlObj.STAT was last
%                    populated and genuinely need a fresh compile.
%   gridCols       : optional, default {'chans','t'}. Column names to pull
%                    from G as additional grid dimensions (alongside
%                    band) — any name not actually present in G is
%                    silently skipped (e.g. a dfID with no 't' axis at
%                    all), not an error.
%
%   T : table, one row per (trial, <gridCols>, band): subject, condition,
%       trial, <gridCols...>, band, bandPower. 'trial' is always included
%       (real STAT.trialNumber, not a gridCol) -- needed to correctly
%       average bandPower ACROSS chans within the same trial for the
%       global-confound diagnostic (build_globalSignalTable/
%       build_residualTable), not something to loop a grid cell over.

    t0 = tic;
    if nargin < 2 || isempty(forceRecompile), forceRecompile = false; end
    if nargin < 3 || isempty(gridCols), gridCols = {'chans', 't'}; end
    if ~forceRecompile && ismember('STAT', fieldnames(mdlObj)) ...
            && istable(mdlObj.STAT) && height(mdlObj.STAT) > 0
        STAT = mdlObj.STAT;
        fprintf('[build_bandPowerRegionTable] reusing mdlObj.STAT (%d rows) -- no recompile\n', height(STAT));
    else
        fprintf('[build_bandPowerRegionTable] mdlObj.STAT empty or forceRecompile=true -- calling compileSTAT()...\n');
        [STAT, ~, ~] = mdlObj.compileSTAT();   % mdlObj's own method -- Figure-independent
        fprintf('[build_bandPowerRegionTable] compileSTAT() done (%d rows) -- %.2f s\n', height(STAT), toc(t0));
    end

    fprintf('[build_bandPowerRegionTable] flattening via nexOp_stackSTAT...\n');
    t1 = tic;
    [Z, G, ~] = nexOp_stackSTAT(STAT);  % Z: [nRows x nBands], G: aligned row-for-row
    fprintf('[build_bandPowerRegionTable] stackSTAT done: Z=%s (%.2f MB) -- %.2f s\n', ...
        mat2str(size(Z)), numel(Z) * 8 / 1e6, toc(t1));

    bandLabels = string(STAT.ax(1).f);
    fprintf('[build_bandPowerRegionTable] band labels: %s\n', strjoin(bandLabels, ', '));
    if numel(bandLabels) ~= size(Z, 2)
        error('build_bandPowerRegionTable:bandMismatch', ...
            ['STAT.ax(1).f has %d labels but Z has %d columns -- pMap.f''s ' ...
             'pooling may not have run (needsHR / block-PCA FTR instead of ' ...
             'plain pool-mode?), or band labels aren''t canonical across rows.'], ...
            numel(bandLabels), size(Z, 2));
    end

    conditionVar = char(mdlObj.dfID_target);
    if ~ismember(conditionVar, G.Properties.VariableNames)
        % mdlObj.dfID_target/collector.Target.Y stores the bare target
        % name (e.g. "responseThreshold_g"), but an HDF5-backed target
        % category's actual STAT/G column goes through nexOp_compileSTAT's
        % own "h5--" -> "h5_" categoryID naming convention, landing as
        % "h5_responseThreshold_g" -- not the bare name. Try that
        % h5-prefixed variant before giving up.
        h5Var = ['h5_' conditionVar];
        if ismember(h5Var, G.Properties.VariableNames)
            fprintf(['[build_bandPowerRegionTable] dfID_target "%s" not found verbatim -- ' ...
                     'using h5-prefixed column "%s" instead (Nexus''s h5--/h5_ naming ' ...
                     'convention for HDF5-backed target categories).\n'], conditionVar, h5Var);
            conditionVar = h5Var;
        else
            error('build_bandPowerRegionTable:noConditionVar', ...
                'dfID_target "%s" (or "%s") not found among STAT''s own columns in G.', ...
                conditionVar, h5Var);
        end
    end
    rawCondition = G.(conditionVar);
    if isstring(rawCondition) || ischar(rawCondition) || iscellstr(rawCondition)
        % An HDF5-backed numeric target can come back as string (dtsIO's
        % own read path for this dfID type) -- nexOp_quantizeY's very
        % first gate is isnumeric(), so a string column is guaranteed to
        % pass through unquantized regardless of nBins. str2double here,
        % not a categorical/grouping cast, since this is meant to be the
        % same continuous value stat2dm_supervised.m quantizes.
        fprintf(['[build_bandPowerRegionTable] conditionVar "%s" is %s -- converting to ' ...
                 'double via str2double before quantizing.\n'], conditionVar, class(rawCondition));
        rawCondition = str2double(string(rawCondition));
        if any(isnan(rawCondition))
            fprintf(['[build_bandPowerRegionTable] WARNING: %d/%d values failed str2double ' ...
                     '(became NaN) -- check conditionVar''s raw string format.\n'], ...
                nnz(isnan(rawCondition)), numel(rawCondition));
        end
    end
    fprintf('[build_bandPowerRegionTable] conditionVar = "%s", raw: %d unique value(s)\n', ...
        conditionVar, numel(unique(rawCondition)));

    % stat2dm_supervised.m quantizes tVar via nexOp_quantizeY before the
    % LDA ever fits on it (mdlObj.collector.Target.nBins, default Inf =
    % pass-through) -- reusing the IDENTICAL call here, not a separately
    % invented threshold, so "condition" here means the same low/high (or
    % N-way) split the LDA actually trained on, not the raw continuous
    % value. Skipping this step is what produced an ~859-level factor on
    % the live run -- unusable as a fitlme fixed effect, and almost
    % certainly why that run looked stuck (an enormous/degenerate design
    % matrix), not merely slow.
    nBins = Inf;
    try
        nBins = mdlObj.collector.Target.nBins;
    catch
    end
    quantCondition = nexOp_quantizeY(rawCondition, nBins);
    if isequal(quantCondition, rawCondition)
        fprintf(['[build_bandPowerRegionTable] WARNING: quantizeY was a pass-through ' ...
                 '(nBins=%s) -- condition is STILL continuous. Check mdlObj.collector.' ...
                 'Target.nBins matches what the LDA actually used.\n'], mat2str(nBins));
    else
        fprintf('[build_bandPowerRegionTable] quantized condition: nBins=%s -> %d unique bin(s): %s\n', ...
            mat2str(nBins), numel(unique(quantCondition)), strjoin(string(unique(quantCondition)), ', '));
    end
    conditionQ = quantCondition;

    gridCols   = gridCols(ismember(gridCols, G.Properties.VariableNames));
    if isempty(gridCols)
        fprintf('[build_bandPowerRegionTable] none of the requested gridCols are G columns -- table has only band as a grid dimension\n');
    else
        fprintf('[build_bandPowerRegionTable] gridCols = %s\n', strjoin(string(gridCols), ', '));
    end

    nRows  = height(G);
    nBands = numel(bandLabels);
    fprintf('[build_bandPowerRegionTable] %d subjects, %d rows, %d bands -> assembling long table (%d rows)...\n', ...
        numel(unique(G.subj_internal)), nRows, nBands, nRows * nBands);

    if ~ismember('trialNumber', G.Properties.VariableNames)
        error('build_bandPowerRegionTable:noTrialNumber', ...
            'G has no trialNumber column -- expected a real STAT column (nexOp_compileSTAT sets it directly).');
    end
    subject   = repmat(string(G.subj_internal), nBands, 1);
    condition = repmat(string(conditionQ), nBands, 1);
    trial     = repmat(G.trialNumber, nBands, 1);
    band      = repelem(bandLabels(:), nRows, 1);
    bandPower = Z(:);   % column-major flatten -- matches the repmat/repelem block order above

    T = table(subject, condition, trial, band, bandPower);

    % side/cci: parsed from sessionLabel_phase when present (real STAT
    % column, e.g. "L-hind-paw", "R-hind-paw-CCI") -- plain columns to
    % FILTER T on before calling build_bandHierarchy, not gridCols to loop
    % automatically. Folding these into the same grid as band/chans/t
    % would pool pre-/post-CCI and left/right into one shared multiple-
    % comparisons correction, which is exactly the conflation a stratified
    % (filter T, then call build_bandHierarchy separately per stratum)
    % design avoids -- pre-CCI baseline sensory coding and post-CCI
    % injury-induced sensitivity never share a model or a correction pool.
    if ismember('sessionLabel_phase', G.Properties.VariableNames)
        phase = string(G.sessionLabel_phase);
        sideCol = repmat(startsWith(phase, 'L'), nBands, 1);
        cciCol  = repmat(contains(phase, 'CCI'), nBands, 1);
        T.side = categorical(sideCol, [true false], {'L','R'});
        T.cci  = cciCol;
        fprintf(['[build_bandPowerRegionTable] side/cci parsed from sessionLabel_phase: ' ...
                 '%d L, %d R, %d pre-CCI, %d post-CCI (trial-level, not nBands-multiplied)\n'], ...
            nnz(startsWith(phase,'L')), nnz(startsWith(phase,'R')), ...
            nnz(~contains(phase,'CCI')), nnz(contains(phase,'CCI')));
    else
        fprintf('[build_bandPowerRegionTable] no sessionLabel_phase in G -- side/cci columns not added\n');
    end

    for gi = 1:numel(gridCols)
        gc = gridCols{gi};
        T.(gc) = repmat(string(G.(gc)), nBands, 1);
        T.(gc) = categorical(T.(gc));
    end
    T.condition = categorical(T.condition);
    T.band      = categorical(T.band);
    fprintf('[build_bandPowerRegionTable] done: T is %d x %d -- total %.2f s\n', ...
        height(T), width(T), toc(t0));
end
