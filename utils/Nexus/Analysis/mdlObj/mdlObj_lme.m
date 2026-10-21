classdef mdlObj_lme < mdlObject
% mdlObj_lme  Linear-mixed-effects model chain, promoted from the proven
% standalone pipeline (build_bandPowerRegionTable.m/build_bandHierarchy.m/
% run_mixedEffectPipeline.m -- all untouched, still used by the standalone
% figures). See Analysis/Statistics/MixedEffect/DESIGN.md.
%
% No standalone "chain" property -- it lives in cfg.fitCfg.entryParams
% (see setChain()) so saveState()/mdlObj_fromState carry it for free, the
% same way LDA's n_components/shrinkage round-trip today.
%
% Stratification (e.g. CCI x side) is not a bespoke concept here -- set
% domain.CTG to the real grouping column names and the INHERITED fit()/
% fitByCombo() already do the rest (one independently-fit child mdlObj_lme
% per combo). fitAndReport() below is the only new orchestration: it calls
% fit() (inherited, unmodified) then assembles whichever shape resulted
% (comboFits, or a single mdlObj.W) into one STAT-shaped RESULTS table --
% one row per combo, each row's df/ax holding the full [band x chans x t x
% mdlStep] grid -- and stores it via storeResult().
%
% WORKED EXAMPLE used in comments throughout this file -- a 3-step chain
% on an HDF5-backed continuous target, binned to 2 levels, with a random
% intercept then a random slope over subject:
%
%   chain = defineModelChain({ ...
%       "df ~ 1 + (1|sessionLabel_subj)", ...                                  % m0
%       "df ~ 1 + h5_responseThreshold_g + (1|sessionLabel_subj)", ...        % m1
%       "df ~ 1 + h5_responseThreshold_g + (1 + h5_responseThreshold_g|sessionLabel_subj)"}); % m2
%   mdlObj.setChain(chain);
%   mdlObj.domain.SWP = ["chans","t"];     % grid dimensions beyond the feature axis --
%                                           % nexFit_lme.m reads this directly (WIP.md #12
%                                           % observation 7); no separate gridCols cfg param
%   mdlObj.domain.CTG = ["cci","side"];   % 2x2 = 4 strata
%   mdlObj.fitAndReport("chainFit1");
%
% chain.variables    = ["sessionLabel_subj","h5_responseThreshold_g"]
% chain.groupingVars = ["sessionLabel_subj"]

    properties
    end

    methods
        function mdlObj = mdlObj_lme(Parent, Origin, dfID_source, headline)
            if nargin < 4, headline = []; end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "lme", dfID_source, [], headline);
            % isHeadless gates BOTH initTargetBus() and setupDomain() --
            % in the live-figure branch, the super() call above already
            % triggered nexFigure_lme(mdlObj) (base mdlObject's own
            % figFcn(mdlObj) call happens INSIDE super(), before this line
            % ever runs), and nexFigure_lme.m calls both itself (same
            % ordering constraint nexFigure_lda.m works under). Calling
            % either again here would just redundantly rebuild the same
            % bus a second time -- harmless but wasteful, and worth not
            % reproducing even though mdlObj_lda.m's own constructor does
            % exactly that for initTargetBus() (not guarded there).
            isHeadless = isprop(mdlObj.nexon, 'settings') && ...
                         isfield(mdlObj.nexon.settings, 'headless') && ...
                         mdlObj.nexon.settings.headless;
            if isHeadless
                mdlObj.initTargetBus();   % Y dropdown + nBins spinner -- discoverability
                                           % + quantization for whichever real column is
                                           % designated Target; formulas may reference any
                                           % column regardless of this selection.
                mdlObj.setupDomain();
            end
        end

        function setupDomain(mdlObj)
            % Mirrors mdlObj_lda.setupDomain -- builds the full collector
            % triad headlessly (figure path builds the same via nexFigure_lme).
            mdlObj.initDomainBus();
            % FTR defaults to "None" for LME -- unlike LDA/SSM, LME has no
            % feature-axis consumer (getDesignMatrix() is a no-op); FTR's
            % only other effect was seeding REG's candidate list, and that
            % coupling is now removed (nexOp_computeREGOptions.m no longer
            % depends on FTR -- see its own header) specifically so this
            % default never blocks picking REG="chans"/"unit" independently
            % of FTR later (e.g. firing-rate/unit work). REG itself already
            % defaults to "None" via the inherited initDomainBus() above,
            % unaffected by this.
            bus = mdlObj.collector.Domain;
            % bus is a handle object (nexObj_selectionBus), not a plain
            % struct -- isfield(bus, ...) always returns false on it even
            % when the property genuinely exists (same documented pitfall
            % as DF_postOp in nexObj/CLAUDE.md's CLR Bus section). Use
            % fieldnames-membership instead, same workaround already used
            % in nexOp_compileSTAT.m for this exact issue.
            if ismember('selKeys', fieldnames(bus)) && isfield(bus.selKeys, 'FTR') && ~ismember("None", bus.selKeys.FTR)
                bus.selKeys.FTR    = ["None", bus.selKeys.FTR];
                bus.selections.FTR = 1;
            end
            mdlObj.domain.FTR = "None";
            mdlObj.initPointerBus();
            mdlObj.initViewBus();
        end

        function setChain(mdlObj, chain)
        % chain's real home is cfg.fitCfg.entryParams (see class header),
        % not an independent property -- this is a thin convenience
        % wrapper so callers don't need to know the internal cfg path.
            mdlObj.cfg.fitCfg.entryParams.chain = chain;
        end

        function getDesignMatrix(mdlObj)
        % Thin no-op override -- fitlme fits a long-format table directly
        % (built by buildLongSTAT.m), never an X/Y design matrix. Exists
        % only so the inherited fit()/fitByCombo()'s unconditional
        % getDesignMatrix() call doesn't error.
            mdlObj.trainMask = true(height(mdlObj.STAT), 1);
            mdlObj.DM = struct();
        end

        function fitAndReport(mdlObj, resultID)
        % fit() (inherited) already dispatches to fitByCombo() when
        % domain.CTG names real STAT columns, or to the single-model path
        % (cfg.fitCfg.fcn = nexFit_lme) otherwise -- nothing new needed
        % there. This assembles whichever shape resulted into one
        % STAT-shaped RESULTS table (one row per combo, or one row total)
        % and stores it.
        %
        % COMBO CASE (domain.CTG = ["cci","side"], worked example):
        %   after fit() -> mdlObj.comboFits is a 1x4 struct array:
        %     comboFits(1).key   = struct('cci', 0, 'side', "L")
        %     comboFits(1).child = <mdlObj_lme child, child.W = computeSignificance's output>
        %     comboFits(2).key   = struct('cci', 0, 'side', "R")
        %     comboFits(3).key   = struct('cci', 1, 'side', "L")
        %     comboFits(4).key   = struct('cci', 1, 'side', "R")
        %   child.W (each child) = struct('df', pGrid, 'ax', ax, 'T_long', T_long)
        %   -- see computeSignificance's own header for pGrid/ax/T_long's
        %   exact shape.
        %   Assembled T (4 rows):
        %       cci | side |        df        |        ax        |  ptr | T_long
        %       ----+------+------------------+-------------------+-----+-------
        %        0  |  "L" | [nChans x nT x 3] | struct(chans,t,mdlStep) | ... | <long table, this stratum>
        %        0  |  "R" | [nChans x nT x 3] | struct(chans,t,mdlStep) | ... | <long table, this stratum>
        %        1  |  "L" | [nChans x nT x 3] | struct(chans,t,mdlStep) | ... | <long table, this stratum>
        %        1  |  "R" | [nChans x nT x 3] | struct(chans,t,mdlStep) | ... | <long table, this stratum>
        %   (3 = nSteps in the worked-example chain; "f"/band collapsed
        %   out here only because this particular example's gridCols =
        %   {'chans','t'} put band on its own -- band would be a 4th grid
        %   dimension in df/ax if it weren't quantized away by pMap.f.)
        %   T_long is what nexObj_violin reads (via R.T_long{selectedRow})
        %   for the raw trial-level distribution -- DESIGN.md section 4.
        %
        % NO-COMBO CASE (domain.CTG empty): single-model path runs instead
        % -- mdlObj.W = struct('df', pGrid, 'ax', ax, 'T_long', T_long)
        % directly, and T is built as ONE row with no key columns at all,
        % just df/ax/ptr/T_long.
            mdlObj.fit();
            if ~isempty(mdlObj.comboFits)
                nCombos = numel(mdlObj.comboFits);
                keyTbl  = struct2table([mdlObj.comboFits.key], 'AsArray', true);
                dfCol = cell(nCombos, 1);
                axCol = cell(nCombos, 1);
                ptrCol = cell(nCombos, 1);
                tLongCol = cell(nCombos, 1);
                for k = 1:nCombos
                    dfCol{k}    = mdlObj.comboFits(k).child.W.df;
                    axCol{k}    = mdlObj.comboFits(k).child.W.ax;
                    ptrCol{k}   = nexInit_axisPointer(dfCol{k}, axCol{k});
                    tLongCol{k} = mdlObj.comboFits(k).child.W.T_long;
                end
                T = keyTbl;
                T.df     = dfCol;
                T.ax     = axCol;
                T.ptr    = ptrCol;
                T.T_long = tLongCol;
            else
                T = table({mdlObj.W.df}, {mdlObj.W.ax}, ...
                    {nexInit_axisPointer(mdlObj.W.df, mdlObj.W.ax)}, {mdlObj.W.T_long}, ...
                    'VariableNames', {'df', 'ax', 'ptr', 'T_long'});
            end
            % sigThreshold marks this RESULTS table's .df as a p-value grid
            % and gives the default cutoff for significance-star rendering
            % -- a plain data column (same convention T_long already rides
            % along as), not a hardcoded "this came from mdlObj_lme" check
            % anywhere downstream. Any consumer (nexObj_monoGram today)
            % checks column PRESENCE to decide whether .df means p-values
            % at all, and reads the per-row VALUE as the live threshold --
            % nexObj_monoGram's own sigThreshold spinner writes back into
            % this same column per-row, so each stratum keeps its own
            % interactively-titrated cutoff (DESIGN.md section 5's
            % deferred "DF-like basin with a keyword" idea, realized here
            % as a literal column rather than a new bus).
            T.sigThreshold = repmat(0.05, height(T), 1);
            mdlObj.storeResult(resultID, T);
        end

        % -- Results lifecycle -- mirrors mdlObj_linear.m's pattern so
        % RESULTS become browsable via SRC/VW, same as every other
        % predictor mdlObj.

        function storeResult(mdlObj, resultID, data)
            mdlObj.RESULTS.(resultID) = data;
            bus = mdlObj.collector.View;
            if ~ismember(resultID, bus.selKeys.SRC)
                bus.selKeys.SRC = [bus.selKeys.SRC, string(resultID)];
                if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                        && isvalid(bus.listBoxes.SRC)
                    bus.listBoxes.SRC.String = cellstr(bus.selKeys.SRC);
                    bus.listBoxes.SRC.Max    = numel(bus.selKeys.SRC);
                end
            end
            mdlObj.applySRC(resultID);

            if isstruct(mdlObj.Partners) && isfield(mdlObj.Partners, 'viewer') && ...
                    ~isempty(mdlObj.Partners.viewer) && isvalid(mdlObj.Partners.viewer)
                mdlObj.Partners.viewer.push(resultID, data);
            end
        end

        function applySRC(mdlObj, srcKey)
        % srcKey = 'fit' -> clear VW/CLR (nothing comparative to show yet).
        % srcKey = <resultID> -> populate VW/CLR from that RESULTS entry's rows.
            srcKey = char(srcKey);
            isFit  = strcmp(srcKey, 'fit');
            bus    = mdlObj.collector.View;

            if isfield(bus.listBoxes, 'SRC') && ~isempty(bus.listBoxes.SRC) ...
                    && isvalid(bus.listBoxes.SRC)
                idx = find(bus.selKeys.SRC == string(srcKey), 1);
                if ~isempty(idx)
                    bus.listBoxes.SRC.Value = idx;
                    bus.selections.SRC      = idx;
                end
            end

            if isFit
                bus.selKeys.CLR = "";
                bus.selKeys.VW  = "";
                if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                        && isvalid(bus.listBoxes.VW)
                    bus.listBoxes.VW.String = {};
                    bus.listBoxes.VW.Value  = [];
                end
                if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                        && isvalid(bus.listBoxes.CLR)
                    bus.listBoxes.CLR.String = {};
                    bus.listBoxes.CLR.Value  = [];
                end
            elseif isfield(mdlObj.RESULTS, srcKey)
                mdlObj.refreshVW(srcKey);

                R = mdlObj.RESULTS.(srcKey);
                if istable(R) && ismember('ax', R.Properties.VariableNames)
                    axNames = string(fieldnames(R.ax{1}))';
                    clrOpts = axNames(~ismember(axNames, "perm"));
                else
                    clrOpts = string.empty(1, 0);
                end
                if isempty(clrOpts), clrOpts = "mdlStep"; end
                bus.selKeys.CLR    = clrOpts;
                bus.selections.CLR = 1;
                if isfield(bus.listBoxes, 'CLR') && ~isempty(bus.listBoxes.CLR) ...
                        && isvalid(bus.listBoxes.CLR)
                    bus.listBoxes.CLR.String = cellstr(clrOpts);
                    bus.listBoxes.CLR.Max    = numel(clrOpts);
                    bus.listBoxes.CLR.Value  = 1;
                end
            end

            try
                nexFigure_lme_renderSRC(mdlObj, srcKey);
            catch
                % Headless / figure not yet built (Phase 4) -- SRC/VW/CLR
                % bookkeeping above still applies; nothing to render yet.
            end
        end

        function refreshVW(mdlObj, resultID)
        % Populate VW from RESULTS.(resultID)'s own grouping columns (the
        % combo-key columns from fitAndReport -- e.g. cci/side -- or none
        % at all for the single-stratum case).
            if ~isfield(mdlObj.RESULTS, resultID), return; end
            R = mdlObj.RESULTS.(resultID);

            if istable(R)
                structural = ["df", "ax", "ptr", "T_long"];
                groupCols  = setdiff(string(R.Properties.VariableNames), structural, 'stable');
                if isempty(groupCols)
                    rowLabels = arrayfun(@(i) sprintf("row_%d", i), ...
                                        (1:height(R))', 'UniformOutput', false);
                    rowLabels = string(rowLabels);
                else
                    rowLabels = string(R.(char(groupCols(1))));
                    for c = 2:numel(groupCols)
                        rowLabels = rowLabels + " | " + string(R.(char(groupCols(c))));
                    end
                end
            else
                rowLabels = string(resultID);
            end

            bus = mdlObj.collector.View;
            nVW = numel(rowLabels);
            bus.selKeys.VW    = rowLabels;
            bus.selections.VW = 1:nVW;

            if isfield(bus.listBoxes, 'VW') && ~isempty(bus.listBoxes.VW) ...
                    && isvalid(bus.listBoxes.VW)
                bus.listBoxes.VW.String = cellstr(rowLabels);
                bus.listBoxes.VW.Max    = nVW;
                bus.listBoxes.VW.Value  = 1:nVW;
            end
        end

        function gridResult = computeSignificance(mdlObj, T_long, chain) %#ok<INUSL>
        % Chain-walking fitlme/compare per grid cell -- modeled on
        % build_bandHierarchy.m's proven grid-cell loop and flat BH
        % correction (build_bandHierarchy.m itself is untouched; this is a
        % new, chain-driven sibling, nested here per plan decision 3).
        % PUBLIC, not private -- MATLAB's access control only restricts
        % between CLASSES, never to one specific external function file,
        % so "callable only by nexFit_lme.m" was never actually achievable
        % via private/protected given cfg.fitCfg.fcn must be a standalone
        % function (same convention as nexFit_lda.m/nexFit_linear.m,
        % never a method) -- it's nested here as a matter of ownership/
        % documentation, not enforced access.
        %
        % Grid dimensions = every T_long column except chain.variables/
        % trial/df -- this naturally includes the feature axis
        % (buildLongSTAT's own column, whatever it's really called) and
        % any extra gridCols, with no need to tell them apart here (plan
        % decision 1 -- no privileged axis).
        %
        % mdlStep labels are chain-structural (depend only on chain.steps'
        % formulas, never on the fitted data), so computed once up front,
        % not per grid cell -- see diffChainStep/splitFormula below.
        %
        % Returns struct('df', pGrid, 'ax', ax, 'T_long', T_long) -- pGrid
        % is the BH-corrected p-value for each (grid cell x mdlStep); m0's
        % own slice is always NaN (nothing to compare it against). T_long
        % (the long-format table passed in) rides along unchanged, so the
        % RESULTS row this becomes (fitAndReport) can carry the raw
        % trial-level data forward for nexObj_violin without a second
        % compile/flatten (DESIGN.md section 4). The raw, per-step
        % newly-added-term ESTIMATE is intentionally not folded into the
        % pGrid facet itself (a further facet, WIP #11-style -- deferred,
        % not needed by nexObj_monoGram's first pass).
        %
        % T_long going IN (buildLongSTAT.m's output, worked example --
        % one row per trial x feature-axis-level x gridCol-combo):
        %   trial | chans |  t   |   f    |  df   | h5_responseThreshold_g | sessionLabel_subj
        %   ------+-------+------+--------+-------+-------------------------+-------------------
        %     1   |  "C3" | "-1" | "gamma"| 0.42  |           1             |      "rat07"
        %     1   |  "C3" | "-1" | "beta" | 0.19  |           1             |      "rat07"
        %     1   |  "C4" | "-1" | "gamma"| 0.51  |           1             |      "rat07"
        %    ...  |  ...  | ...  |  ...   |  ...  |          ...            |       ...
        %   ("chans"/"t" from gridCols; "f" is buildLongSTAT's own
        %   resolved feature-axis name/labels -- here still literally "f"
        %   with band names as its categories, since this worked example
        %   reuses the band-power pipeline's own pMap.f pooling. A
        %   different domain/metric would carry a differently-named,
        %   differently-valued feature axis instead -- computeSignificance
        %   never assumes "f" or "band" specifically, see gridVars below.)
            % chain.variables is a COLUMN string array (built via toks(:)
            % in defineModelChain.m) -- cellstr() preserves that column
            % shape, so concatenating with the ROW cell {'trial','df'}
            % via [A, B] needs A transposed to a row first, or horzcat
            % errors on mismatched row counts.
            gridVars = setdiff(T_long.Properties.VariableNames, ...
                [cellstr(chain.variables)', {'trial', 'df'}], 'stable');
            % gridVars = {'chans','t','f'} for the table above (order from
            % T_long's own column order, not alphabetical).
            if isempty(gridVars)
                error('mdlObj_lme:computeSignificance:noGridVars', ...
                    'T_long has no grid columns beyond chain.variables/trial/df.');
            end
            gridLevels = cellfun(@(v) categories(T_long.(v)), gridVars, 'UniformOutput', false);
            % gridLevels = { {"C3";"C4";...}, {"-1";"0";"1";...}, {"beta";"gamma";...} }
            gridSizes  = cellfun(@numel, gridLevels);
            % gridSizes  = [nChans, nT, nBands]  e.g. [16, 5, 2]
            nCells     = prod(gridSizes);
            % nCells = 16*5*2 = 160 -- one independent fitlme chain per cell

            nSteps = numel(chain.steps);   % 3 for the worked example (m0/m1/m2)
            stepLabels = strings(nSteps, 1);
            stepLabels(1) = chain.steps(1).step;
            for i = 2:nSteps
                suffix = diffChainStep(chain.steps(i-1).formula, chain.steps(i).formula);
                if suffix == ""
                    stepLabels(i) = chain.steps(i).step;
                else
                    stepLabels(i) = chain.steps(i).step + "_" + suffix;
                end
            end
            % stepLabels = ["m0"; "m1_fe_h5_responseThreshold_g"; "m2_re_h5_responseThreshold_g"]
            % -- the flattened, self-documenting MDL-axis labels from
            % DESIGN.md section 2. Computed ONCE here (chain-structural,
            % not data-dependent), reused for every grid cell below.

            groupingVar = "";
            if ~isempty(chain.groupingVars) && ismember(chain.groupingVars(1), T_long.Properties.VariableNames)
                groupingVar = chain.groupingVars(1);
            end
            % groupingVar = "sessionLabel_subj" -- used only for the
            % per-cell "too few subjects" skip guard below, same role
            % build_bandHierarchy.m's own nSubj<2 check plays.
            fixedVars = setdiff(chain.variables, chain.groupingVars, 'stable');
            % fixedVars = ["h5_responseThreshold_g"] -- used only for the
            % diagnostic print in the catch block below, to pin down
            % WHICH variable actually lacked variation in a failing cell.

            pRaw = nan(nCells, nSteps);
            % pRaw(r,i) = raw (uncorrected) LRT p-value comparing step i-1
            % vs. step i, for grid cell r. Column 1 (m0) stays all-NaN --
            % there is no step "-1" to compare it against. One ROW of
            % pRaw, e.g. pRaw(42,:) = [NaN, 0.031, 0.47], means: at
            % whatever (chans,t,f) combo cell #42 is, adding the fixed
            % effect was significant (p=0.031) but adding the random
            % slope on top of that wasn't (p=0.47).
            progressStep = max(1, round(nCells / 20));
            % Success is silent below (only a skipped/failed cell prints
            % anything), so a long successful run with no failures looks
            % identical to a hang -- a periodic heartbeat every ~5% of
            % cells keeps that visible without flooding the console the
            % way printing every cell would.
            for r = 1:nCells
                if mod(r, progressStep) == 0 || r == nCells
                    fprintf('[mdlObj_lme.computeSignificance] cell %d/%d...\n', r, nCells);
                end
                subs = ind2subVec(gridSizes, r);
                % e.g. r=42 -> subs = [3, 1, 2] meaning
                % chans=gridLevels{1}{3}, t=gridLevels{2}{1}, f=gridLevels{3}{2}
                mask = true(height(T_long), 1);
                for gi = 1:numel(gridVars)
                    lvl  = gridLevels{gi}{subs(gi)};
                    mask = mask & (T_long.(gridVars{gi}) == lvl);
                end
                Tc = T_long(mask, :);
                % Tc = just this one grid cell's rows -- one row per
                % trial (e.g. 24 rows for 24 trials across however many
                % subjects), same shape as build_bandHierarchy.m's own
                % per-cell Tc, just with real column names instead of
                % the fixed condition/subject/bandPower ones.
                tooFewGroups = groupingVar ~= "" && numel(unique(Tc.(char(groupingVar)))) < 2;
                if height(Tc) < 10 || tooFewGroups
                    continue   % pRaw(r,:) stays all-NaN for this cell
                end

                fits = cell(nSteps, 1);
                % fits{i} = a LinearMixedModel object (fitlme's own return
                % type) for chain step i, fit on THIS cell's Tc only --
                % e.g. fits{2} = fitlme(Tc, "df ~ 1 + h5_responseThreshold_g + (1|sessionLabel_subj)")
                %
                % Each step gets its OWN try/catch (rather than one try
                % around the whole step loop) so a rank-deficiency error
                % can be attributed to the exact failing step/formula --
                % m0 is intercept-only and can never be rank-deficient, so
                % if THIS cell fails, it must be m1 or m2, and knowing
                % which one (and that step's own formula) is the key fact
                % the single shared catch below couldn't tell us.
                cellFailed = false;
                try
                    fits{1} = fitlme(Tc, char(chain.steps(1).formula));
                catch ME
                    reportCellFailure(r, nCells, 1, chain.steps(1).formula, ME, ...
                        Tc, gridVars, gridLevels, subs, groupingVar, fixedVars);
                    cellFailed = true;
                end
                if ~cellFailed
                    for i = 2:nSteps
                        try
                            fits{i} = fitlme(Tc, char(chain.steps(i).formula));
                            cmp = compare(fits{i-1}, fits{i});
                            % cmp is fitlme's own compare() output table --
                            % cmp.pValue(2) is the LRT p-value for "does step i
                            % explain significantly more than step i-1".
                            pRaw(r, i) = cmp.pValue(2);
                        catch ME
                            reportCellFailure(r, nCells, i, chain.steps(i).formula, ME, ...
                                Tc, gridVars, gridLevels, subs, groupingVar, fixedVars);
                            break
                        end
                    end
                end
            end

            % Flat BH-FDR within each mdlStep across every grid cell --
            % same correction scope build_bandHierarchy.m uses, just
            % applied once per step instead of once overall (plan decision
            % "Phase 3"). m0 (column 1) has no p-value to correct.
            pCorrected = pRaw;
            for i = 2:nSteps
                % benjaminiHochberg corrects pRaw(:,i) -- all 160 cells'
                % raw p-values for step i -- together, as ONE multiple-
                % comparisons pool. Step i=2's 160 p-values are corrected
                % separately from step i=3's 160 p-values (two independent
                % hypotheses being tested, not pooled into one correction).
                pCorrected(:, i) = benjaminiHochberg(pRaw(:, i));
            end

            pGrid = reshape(pCorrected, [gridSizes, nSteps]);
            % pGrid is now a genuine N-D array, e.g. size [16, 5, 2, 3]
            % (chans x t x f x mdlStep) -- pGrid(3,1,2,2) is the SAME
            % number as pCorrected(42,2) above (r=42 decoded back to its
            % [chans,t,f] subscripts), just reshaped for nexObj_monoGram
            % to surf/Pointer-window directly, exactly like any other DF.
            ax = struct();
            for gi = 1:numel(gridVars)
                ax.(gridVars{gi}) = string(gridLevels{gi});
            end
            ax.mdlStep = stepLabels;
            % ax = struct('chans', ["C3";"C4";...], 't', ["-1";"0";...],
            %             'f', ["beta";"gamma"], 'mdlStep', ["m0";"m1_fe_...";"m2_re_..."])
            % -- one real axis per pGrid dimension, mdlStep included like
            % any other (plan decision 1: no bespoke mdlAxisLabels property).

            % T_long rides along unchanged -- see this method's own header
            % comment above (DESIGN.md section 4's RESULTS-row addition).
            gridResult = struct('df', pGrid, 'ax', ax, 'T_long', T_long);
        end
    end
end

function reportCellFailure(r, nCells, stepIdx, formula, ME, Tc, gridVars, gridLevels, subs, groupingVar, fixedVars)
% Diagnostic for a fitlme failure on one grid cell -- pins down WHICH
% step/formula failed and WHY, rather than leaving it to guesswork.
% Prints: the cell's own axis values, the exact failing formula, NaN
% counts for every variable the formula actually uses, and -- the key
% check for "Fixed Effects design matrix X must be of full column rank"
% specifically -- each fixed-effect variable's distinct-value count
% AFTER dropping rows fitlme itself would drop (any NaN in df or in that
% variable), since a predictor can look perfectly varied in the full
% Tc print yet collapse to a single value once fitlme's own listwise
% deletion is applied.
    fprintf('[mdlObj_lme.computeSignificance] cell %d/%d skipped at step %d (fitlme error): %s\n', ...
        r, nCells, stepIdx, ME.message);
    fprintf('    formula: %s\n', formula);
    try
        cellDesc = strings(1, numel(gridVars));
        for gi2 = 1:numel(gridVars)
            cellDesc(gi2) = sprintf('%s=%s', gridVars{gi2}, string(gridLevels{gi2}{subs(gi2)}));
        end
        fprintf('    cell: %s | height(Tc)=%d', strjoin(cellDesc, ', '), height(Tc));

        dfNanMask = isnan(Tc.df);
        fprintf(' | df: %d/%d NaN', sum(dfNanMask), height(Tc));

        if groupingVar ~= ""
            gVals = unique(Tc.(char(groupingVar)));
            fprintf(' | %s: %d distinct (%s)', groupingVar, numel(gVals), strjoin(string(gVals), ','));
        end

        for fi = 1:numel(fixedVars)
            fv = char(fixedVars(fi));
            if ~ismember(fv, Tc.Properties.VariableNames), continue; end
            fVals = Tc.(fv);
            % Listwise-deletion subset: rows fitlme would actually keep
            % for a model using df + this fixed effect -- the subset
            % whose rank actually matters, not Tc as a whole.
            keep  = ~dfNanMask & ~isnan(double(string(fVals)));
            uVals = unique(fVals);
            uValsKept = unique(fVals(keep));
            fprintf(' | %s: class=%s, %d distinct overall, %d distinct after dropping df-NaN rows (n_kept=%d)', ...
                fv, class(fVals), numel(uVals), numel(uValsKept), sum(keep));
            % Ground truth, not inference -- directly build the plain
            % [intercept, predictor] matrix THIS variable alone would
            % contribute (ignoring the random-effect term entirely, which
            % lives in Z, not X) and check its real numeric rank. If this
            % is already < 2, the predictor genuinely is degenerate
            % (wrong dtype, e.g. accidentally categorical, or truly
            % constant after some cast) -- if it comes back == 2, the
            % rank-deficiency must come from somewhere else in fitlme's
            % own X (e.g. how it encodes this variable internally,
            % which could differ from a plain double column).
            try
                Xcheck = [ones(sum(keep), 1), double(fVals(keep))];
                fprintf(' | rank([1,%s])=%d/%d', fv, rank(Xcheck), size(Xcheck, 2));
            catch
                fprintf(' | rank check failed (double() cast errored -- not numeric)');
            end
        end
        fprintf('\n');
    catch innerME
        fprintf('    (diagnostic print itself failed: %s)\n', innerME.message);
    end
end

function subs = ind2subVec(sizes, r)
% Same mixed-radix decomposition build_bandHierarchy.m uses (first
% dimension fastest-varying) -- ind2sub requires >=2 size elements,
% errors outright for a single-grid-dimension case.
%
% Example: sizes = [16, 5, 2] (chans x t x f), r = 42
%   rem=41 -> subs(1)=mod(41,16)+1=10, rem=floor(41/16)=2
%   rem=2  -> subs(2)=mod(2,5)+1=3,   rem=floor(2/5)=0
%   rem=0  -> subs(3)=mod(0,2)+1=1
%   subs = [10, 3, 1]  (10th chans level, 3rd t level, 1st f level)
    subs = zeros(1, numel(sizes));
    rem  = r - 1;
    for gi = 1:numel(sizes)
        subs(gi) = mod(rem, sizes(gi)) + 1;
        rem = floor(rem / sizes(gi));
    end
end

function pAdj = benjaminiHochberg(pv)
% Flat BH-FDR over one column, NaN entries (skipped cells) left as NaN --
% same algorithm build_bandHierarchy.m already uses, factored out so it's
% not retyped per-step.
%
% Example: pv = [0.01; NaN; 0.04; 0.03; NaN] (5 grid cells, 2 skipped)
%   valid = [1;0;1;1;0], v = [0.01; 0.04; 0.03], m = 3
%   sorted order gives ranks 1,3,2 for v(1),v(2),v(3) respectively
%   adj (BH step-up) -> pAdj = [0.03; NaN; 0.04; 0.04; NaN] (illustrative --
%   exact values depend on the full step-up min-propagation, shown here
%   only to convey shape: same length as pv, NaN preserved where it was)
    pAdj  = nan(size(pv));
    valid = ~isnan(pv);
    v     = pv(valid);
    m     = numel(v);
    if m == 0, return; end
    [~, order] = sort(v);
    adj = nan(m, 1);
    for k = 1:m
        adj(order(k)) = v(order(k)) * m / k;
    end
    for k = m-1:-1:1
        adj(order(k)) = min(adj(order(k)), adj(order(k+1)));
    end
    pAdj(valid) = min(adj, 1);
end

function suffix = diffChainStep(prevFormula, curFormula)
% "_fe_<term>" when curFormula adds a new FIXED-effect term vs.
% prevFormula, "_re_<term>" when it adds a new RANDOM-effect slope term
% instead, "" when nothing new is detected (shouldn't happen for a
% well-formed chain, but m0's own label never calls this anyway).
%
% Example (the worked chain's m1 -> m2 transition):
%   prevFormula = "df ~ 1 + h5_responseThreshold_g + (1|sessionLabel_subj)"
%   curFormula  = "df ~ 1 + h5_responseThreshold_g + (1 + h5_responseThreshold_g|sessionLabel_subj)"
%   splitFormula(prevFormula) -> fixedTerms=["h5_responseThreshold_g"], randTerms=[]
%   splitFormula(curFormula)  -> fixedTerms=["h5_responseThreshold_g"], randTerms=["h5_responseThreshold_g"]
%   newFixed = {} (same fixed terms both sides) -> newRand = ["h5_responseThreshold_g"]
%   suffix = "re_h5_responseThreshold_g"
    [prevFixed, prevRand] = splitFormula(prevFormula);
    [curFixed,  curRand]  = splitFormula(curFormula);
    newFixed = setdiff(curFixed, prevFixed, 'stable');
    newRand  = setdiff(curRand,  prevRand,  'stable');
    if ~isempty(newFixed)
        suffix = "fe_" + newFixed(1);
    elseif ~isempty(newRand)
        suffix = "re_" + newRand(1);
    else
        suffix = "";
    end
end

function [fixedTerms, randTerms] = splitFormula(f)
% Fixed-effect terms = word tokens outside any "(...)" random-effect
% block; random-effect (slope) terms = word tokens before the "|" inside
% each such block, excluding the bare intercept "1".
%
% Example: f = "df ~ 1 + h5_responseThreshold_g + (1 + h5_responseThreshold_g|sessionLabel_subj)"
%   randBlocks = {"(1 + h5_responseThreshold_g|sessionLabel_subj)"}
%   fixedText (randBlocks stripped) = "df ~ 1 + h5_responseThreshold_g + "
%   fixedTerms = ["h5_responseThreshold_g"]   ("df" explicitly excluded)
%   inner = "1 + h5_responseThreshold_g|sessionLabel_subj"
%   parts = ["1 + h5_responseThreshold_g", "sessionLabel_subj"]
%   randTerms = ["h5_responseThreshold_g"]   (tokens from parts(1) only --
%   parts(2), the grouping variable itself, is never a "term" here)
    f = char(f);
    randBlocks = regexp(f, '\([^()]*\)', 'match');
    fixedText = f;
    for i = 1:numel(randBlocks)
        fixedText = strrep(fixedText, randBlocks{i}, '');
    end
    fixedTerms = string(regexp(fixedText, '[A-Za-z_]\w*', 'match'));
    fixedTerms = fixedTerms(fixedTerms ~= "df");

    randTerms = strings(0, 1);
    for i = 1:numel(randBlocks)
        inner = randBlocks{i}(2:end-1);
        parts = split(string(inner), '|');
        if numel(parts) == 2
            toks = string(regexp(char(parts(1)), '[A-Za-z_]\w*', 'match'));
            randTerms = [randTerms; toks(:)]; %#ok<AGROW>
        end
    end
end
