classdef mdlObject < handle

    properties
        headline
        fitPath      % absolute path to saveFit folder — set by saveFit/loadFit
        fitSentinel  % struct(regAxis, ftrAxis, bySubject, canonReg) — canonical REG
                     % set from the last nexOp_alignCoAxes call in compileSTAT; used
                     % by scaleApply_transform to project each new raw per-trial DF
                     % onto the SAME canonical positions the model was fit on
                     % (see CoRegistration_Design.md, "Inference-Time Projection").
                     % canonReg is a flat array when bySubject=false, or a
                     % containers.Map (subject id -> array) when bySubject=true —
                     % compileSTAT canonicalizes per-subject whenever its TF spans
                     % more than one subject, since a REG identity like 'chans'
                     % isn't comparable across different subjects' probes/geometry.
        RESULTS = struct()   % model-diagnostic results (CV scores, eigenspectra, ...)
        nexon
        modelID
        predictorID
        model
        Reducer
        PoolReducer
        HR          % nexHR model tree — nested cell from nexHR_fit (empty when not used)
        FTR_layout  % struct array [{axID,n},...] outermost-first, built by buildFTRLayout
        FTR_blockColRanges  % struct array [{label,cols},...], nexHR_blockColRanges'
                            % own output — set by getDesignMatrix's needsHR branch
                            % (was discarded before); lets fitSWPGrid/nexFit_ssm
                            % narrow an already-reduced DM by FTR-axis block without
                            % recomputing it
        Scaler
        Predictor
        W % fit weights
        DM % design matrix
        py = struct(); % stored pymodules
        CV % cross validation group
        comboFits = struct('key', {}, 'child', {})   % one independently-fit
            % child mdlObj per unique domain.CTG combination present in
            % STAT — see fitByCombo(). Empty (the default) whenever
            % domain.CTG isn't populated: fit()/scaleApply_transform then
            % behave exactly as they always have, off mdlObj.model
            % directly — this is the sole switch between the two modes.
        STAT % stat table with training samples (dereference-able file locations of samples)
        statImportedExternally = false   % set by importSTATFrom()/loadSTAT() --
            % tells fit() to reuse the already-populated STAT instead of
            % unconditionally recompiling (compileSTAT() is often the
            % genuinely expensive step, not fitting itself, for a large
            % DTS). Deliberately a new, explicit opt-in flag rather than
            % reviving fit()'s own commented-out "if isempty(mdlObj.STAT)"
            % guard -- that would also skip recompiling on a normal
            % re-Fit after changing categories/items, which every OTHER
            % mdlObj subclass relies on; this flag only ever becomes true
            % via an explicit importSTATFrom()/loadSTAT() call, so every
            % existing caller's behavior is completely unchanged. Not yet
            % auto-cleared on a categorical selection change (same
            % trigger invalidatePrecompile() listens for) -- call
            % compileSTAT() manually if you import a STAT, then change
            % categories/items, and want a fresh compile afterward.
        STAT_postOp % post-operative STAT table to pass to other vis/analysis
        trainMask % mask training samples for cross validation
        TEST
        TRAIN
        Figure
        domain % dimension handling
        Parent
        pMap
        Children=struct();
        Origin
        Partners
        dfID_source
        dfID_target
        lastOutputLabel = ""  % last outputLabel passed to scaleApply_transform (see there) —
                               % "" if the last Transform call didn't set one. Read by the
                               % Save button (nexFigure_addSaveLoadControls) to fold this
                               % label into the saved fit's folder name instead of a bare
                               % timestamp, so a saved model's name reflects the conditions
                               % it was last transformed under.
        precompiledAligned = []   % cached struct(TF, idxSel, drop) from precompileSTAT() —
                                   % see there, compileSTAT(), and invalidatePrecompile()
        precompileListeners = struct()  % addlistener() handles for precompile invalidation —
                                         % held here so they aren't garbage-collected
        precompileWatchersWired = false
        cfg
        collector
        UserData
    end

    methods
        function mdlObj = mdlObject(Parent, Origin, modelID, dfID_source, predictorID, headline)
            % cebra = py.importlib.import_module('cebra');
            % args = extractMethodCfg('model_cebra');
            % neural network handle to train and infer from a neural
            % mdlObj.modelObj = model_cebra(cebra, args);                        
            % network, etc.
            if nargin >= 6 && ~isempty(headline)
                mdlObj.headline = headline;
            end
            mdlObj.modelID=modelID;
            mdlObj.Parent=Parent;
            nexOp_addChild(Parent, mdlObj);
            % modelTag = sprintf()
            % Parent.Children.(modelTag)=mdlObj;
            if isempty(Origin)
                mdlObj.Origin=Parent;
            else
                mdlObj.Origin=Origin;
            end
            try
                mdlObj.pMap=mdlObj.Origin.pMap;
            catch e
                disp(getReport(e));
            end
            switch class(Parent)
                case "Nexon"
                    mdlObj.nexon=Parent;
                otherwise
                    mdlObj.nexon=Parent.nexon;
            end                        
            mdlObj.dfID_source = dfID_source;
            mdlObj.dfID_target = sprintf("%s_%s",mdlObj.modelID, mdlObj.dfID_source);
            initFcn = str2func(sprintf("model_%s",mdlObj.modelID));
            try
                mdlObj.model = initFcn();
            catch
                initArgs = extractMethodCfg(sprintf('model_%s',mdlObj.modelID));
                mdlObj.model = initFcn(initArgs);
            end
            % check for (and initialize) predictor
            if nargin > 4
                mdlObj.predictorID=predictorID;
                if ~isempty(predictorID)                    
                    predInitFcn=str2func(sprintf("mdlObj_%s",predictorID));
                    mdlObj.Predictor = predInitFcn(mdlObj, Origin, mdlObj.dfID_target);
                else
                    mdlObj.Predictor=mdlObj;
                end
            end
            % PARAMS INIT
            mdlObj.cfg.cvCfg.entryParams.nFolds=5;
            mdlObj.cfg.cvCfg.entryParams.nPermute=50;
            fitFcn_str = sprintf("nexFit_%s",mdlObj.modelID);
            mdlObj.cfg.fitCfg = nex_generateCfgObj(str2func(fitFcn_str));
            mdlObj.cfg.dmCfg.format="stack";
            % SCALER INIT
            try
                sklearnPreProc = py.importlib.import_module('sklearn.preprocessing');
                mdlObj.Scaler  = struct('model', sklearnPreProc.StandardScaler());
            catch
                mdlObj.Scaler  = struct('model', []);
            end
            % DOMAIN INIT
            try
                mdlObj.domain = nexInit_domain(mdlObj.Origin.DF_postOp);
            catch
                mdlObj.domain = nexInit_domain([]);
            end
            % Build Figure (skipped in headless mode)
            % isfield() on mdlObj.nexon (a handle object) always returns
            % false regardless of whether the property genuinely exists --
            % verified directly (not assumed): isfield() never works on
            % ANY object, handle or dynamicprops-based alike, only on
            % plain structs. isprop() is the correct function for "does
            % this OBJECT have this property" -- mdlObj.nexon.settings
            % itself IS a plain struct, so isfield() on THAT stays correct.
            isHeadless = isprop(mdlObj.nexon, 'settings') && ...
                         isfield(mdlObj.nexon.settings, 'headless') && ...
                         mdlObj.nexon.settings.headless;
            if ~isHeadless
                figFcn = str2func(sprintf("nexFigure_%s", mdlObj.modelID));
                figFcn(mdlObj);
                mdlObj.applyHeadline();
                nexRegister_figure(mdlObj.nexon, mdlObj);   % reachable registry for router traversal + closeFcn cleanup
            end
        end

        function initTargetBus(mdlObj)
            % Seed collector.Target.Y from Origin's categorical column names
            % plus any HDF5 dfIDs present in the active DTS.
            try
                S_cat  = nex_returnSelectionMask(mdlObj.Origin.selectionBus.categories);
                catIDs = string(struct2cell(S_cat))';
                catIDs = strrep(catIDs(~strcmp(catIDs, "None")), "--", "_");
                if isempty(catIDs), catIDs = "sessionLabel_phase"; end
            catch
                catIDs = "sessionLabel_phase";
            end

            % Append HDF5 dfIDs so numeric per-trial columns (e.g. withdrawalScore)
            % are selectable as regression targets.
            try
                DTS      = mdlObj.nexon.console.BASE.DTS;
                allIDs   = dtsIO_readDFIDs(DTS);
                exclude  = ["sessionLabel","trialNumber","h5_path","h5_root"];
                h5IDs    = allIDs(~ismember(allIDs, [catIDs, exclude]));
                catIDs   = [catIDs, h5IDs];
            catch
            end

            mdlObj.collector.Target.Y       = catIDs(1);
            mdlObj.collector.Target.options = catIDs;
            mdlObj.collector.Target.nBins   = Inf;
            mdlObj.applyTargetBus();
        end

        function applyTargetBus(mdlObj)
            % Sync dfID_target from collector.Target.Y.
            % Called after any interactive Target selection change.
            if isfield(mdlObj.collector, 'Target') && isfield(mdlObj.collector.Target, 'Y')
                mdlObj.dfID_target = string(mdlObj.collector.Target.Y);
            end
        end

        function applyDomainBus(mdlObj)
            % Sync mdlObj.domain from collector.Domain selections.
            % Called after any interactive Domain listbox change.
            if ~isfield(mdlObj.collector, 'Domain'), return; end
            sel = nex_returnSelectionMask(mdlObj.collector.Domain);
            if isfield(sel, 'DN')  && ~isempty(sel.DN),  mdlObj.domain.DN  = string(sel.DN);  end
            if isfield(sel, 'FTR') && ~isempty(sel.FTR), mdlObj.domain.FTR = string(sel.FTR); end
            if isfield(sel, 'MSR') && ~isempty(sel.MSR), mdlObj.domain.MSR = string(sel.MSR); end
            if isfield(sel, 'REG') && ~isempty(sel.REG)
                newREG = string(sel.REG);
                % REG changing means the next compileSTAT() would canonicalize
                % a different axis entirely — a cached precompiledAligned from
                % the old REG is meaningless against it.
                if ~isequal(newREG, mdlObj.domain.REG)
                    mdlObj.invalidatePrecompile();
                end
                mdlObj.domain.REG = newREG;
            end
        end

        function refreshREG(mdlObj)
            % Recompute REG listbox items when FTR changes. REG candidates
            % derive from co-index pairs of the selected FTR axis, so the
            % available registration axes always track the active feature space.
            try
                srcAx = mdlObj.Origin.DF_postOp.ax;
            catch
                return;
            end
            regOpts = nexOp_computeREGOptions(string(mdlObj.domain.FTR), srcAx);
            bus = mdlObj.collector.Domain;
            if ~isfield(bus.selKeys, 'REG'), return; end
            bus.selKeys.REG = regOpts;
            lb = bus.listBoxes.REG;
            if isempty(lb) || ~isvalid(lb), return; end
            lb.String = cellstr(regOpts);
            curIdx = find(string(regOpts) == string(mdlObj.domain.REG), 1);
            if isempty(curIdx)
                if ~isequal(mdlObj.domain.REG, "None")
                    mdlObj.invalidatePrecompile();
                end
                mdlObj.domain.REG = "None";
                lb.Value = 1;
            else
                lb.Value = curIdx;
            end
        end

        function refreshPointer(mdlObj)
        % Refresh collector.Pointer listboxes from Origin.DF_postOp.ax.
        % Called after pMap changes update the pooled axis labels (lazy path).
        % Mirrors nexObj_stateSpace.refreshPointer but sources from Origin.
            if ~isfield(mdlObj.collector, 'Pointer') || isempty(mdlObj.collector.Pointer)
                return;
            end
            try
                newAx = mdlObj.Origin.DF_postOp.ax;
            catch
                return;
            end
            mdlObj.refreshPointerAxes_(newAx);
        end

        function refreshPointerAxes_(mdlObj, newAx)
        % Shared remap-or-select-all logic behind refreshPointer and
        % refreshPointerFromPool: for each axis field newAx shares with
        % collector.Pointer, remap the current selection onto the new
        % values (by numeric range) when both old and new are numeric,
        % else fall back to "select all" (this codebase's established
        % no-op / pass-through convention — see applyPointer's own comment).
            bus = mdlObj.collector.Pointer;
            axFields = fieldnames(newAx);
            axFields = axFields(~strcmp(axFields, 'latent'));
            for i = 1:numel(axFields)
                ax = axFields{i};
                if ~isfield(bus.selKeys, ax), continue; end
                newVals = newAx.(ax);
                oldVals = bus.selKeys.(ax);
                if isequal(newVals, oldVals), continue; end
                nVals    = numel(newVals);
                curSel   = bus.selections.(ax);
                validSel = curSel(curSel >= 1 & curSel <= numel(oldVals));
                if ~isempty(validSel) && isnumeric(oldVals) && isnumeric(newVals)
                    selRange = oldVals(validSel);
                    newSel   = find(newVals >= min(selRange) & newVals <= max(selRange));
                else
                    newSel = [];
                end
                if isempty(newSel), newSel = 1:nVals; end
                bus.selKeys.(ax)    = newVals;
                bus.selections.(ax) = newSel;
                lb = [];
                if isfield(bus.listBoxes, ax), lb = bus.listBoxes.(ax); end
                if ~isempty(lb) && isvalid(lb)
                    lb.String = newVals;
                    lb.Max    = nVals;
                    lb.Value  = newSel;
                end
            end
        end

        function refreshPointerFromPool(mdlObj, TF1, subjID)
        % Seed/refresh EVERY collector.Pointer axis from a canonical (or,
        % absent REG, just current) per-trial DF's axes, pooled through
        % mdlObj's CURRENT pMap — cheap, label-only (nexOp_poolAx never
        % touches .df, only pm.getBinEdges), so this is safe to call as
        % often as needed with no real-pooling cost and no "double pooling"
        % of actual data: real data pooling happens exactly once, at real
        % Fit/CV time, via nexOp_compileSTAT's own nexOp_poolAxes call.
        %
        % TF1 (optional): a single canonical per-trial DF struct (e.g. the
        % TF{1} a fresh nexOp_compileSTAT alignment just produced). Omit to
        % use mdlObj.precompiledAligned.TF{1} instead (the cached result of
        % the last Compile press).
        %
        % Supersedes the old REG-only refreshPointerFromSentinel: pooling a
        % co-indexed pair (e.g. chans/unit) through nexOp_poolAx propagates
        % region labels to BOTH axes when REG is in mapID/region mode —
        % matching what real pooling (nexOp_poolAxes) actually does to
        % STAT.ax, rather than resetting the sibling to a generic 1:nVals
        % placeholder — so it now generalizes to every pMap-pooled axis
        % (t, f, ...), not just REG, with one shared mechanism.
        %
        % Called from nexOp_compileSTAT right after a FRESH alignment
        % (Compile press, or a cold Fit that skipped Compile) — never on a
        % cache-reusing compileSTAT() call — so a Pointer/pMap subselection
        % made afterward survives into repeated Fits untouched.
        %
        % subjID (optional): the subject(s) TF1 represents — a single
        % subject, several (the cross-subject union representative
        % nexOp_compileSTAT seeds this with when per-subject canonicalization
        % ran), or omitted/empty. Threaded into nexOp_poolAx so region-mode
        % (mapID) pooling resolves the right subject-specific registry
        % regMap for THIS preview too, not just real data pooling (Nexus
        % WIP.md #10).
            if nargin < 3, subjID = string.empty; end
            if nargin < 2 || isempty(TF1)
                if isempty(mdlObj.precompiledAligned) || isempty(mdlObj.precompiledAligned.TF)
                    fprintf(['[mdlObject.refreshPointerFromPool] no-op — nothing ' ...
                             'compiled yet (mdlObj.precompiledAligned is empty). ' ...
                             'Press Compile or Fit once first, then poolMap changes ' ...
                             'will update Pointer live.\n']);
                    return;
                end
                TF1 = mdlObj.precompiledAligned.TF{1};
            end
            if isempty(mdlObj.pMap), return; end
            if ~isfield(mdlObj.collector, 'Pointer') || isempty(mdlObj.collector.Pointer)
                return;
            end
            try
                ax_out = nexOp_poolAx(mdlObj.pMap, TF1, [], subjID);
            catch e
                fprintf('[mdlObject] refreshPointerFromPool: %s\n', e.message);
                return;
            end

            % Co-indexed sibling of REG (e.g. 'unit' when REG='chans') has
            % no real cross-trial canonical identity of its own —
            % nexOp_alignCoAxes deliberately 0/""-pads it per DF
            % (structural-absence marker, correct in isolation: two
            % sessions' "unit 12" at the same channel aren't the same
            % neuron unless REG is 'unit' itself). TF1 is only ONE trial,
            % so unless pMap has already relabeled this sibling into
            % something real (mapID/region names, or its own bin edges —
            % nexOp_poolAx did that above), what's left here is still that
            % one trial's own mostly-absent slice, which would otherwise
            % leak into the Pointer bus as if it were the global option
            % list. What actually matters is POSITION: canonical REG slot
            % k is already the same physical slot in every trial (that's
            % alignCoAxes's whole guarantee), so a synthetic 1:nCanon
            % sequence is both correct and cheap here — no need to scan
            % every trial for raw values that aren't comparable across
            % sessions anyway when REG isn't the sibling itself.
            try
                regAxis = char(mdlObj.domain.REG);
                if ~strcmp(regAxis, 'None') && isfield(ax_out, regAxis)
                    coIdx = nexOp_coIndexPairs(TF1.ax);
                    for p = 1:numel(coIdx)
                        pair = coIdx{p};
                        if ~ismember(regAxis, pair), continue; end
                        for m = 1:numel(pair)
                            sib = char(pair{m});
                            if strcmp(sib, regAxis), continue; end
                            if isfield(ax_out, sib) && isequal(ax_out.(sib), TF1.ax.(sib))
                                % nexOp_poolAx passed it through untouched
                                % — still raw/padded from alignCoAxes.
                                ax_out.(sib) = (1:numel(ax_out.(regAxis)))';
                            end
                        end
                    end
                end
            catch
            end

            mdlObj.refreshPointerAxes_(ax_out);
        end

        function initViewBus(mdlObj)
        % Build collector.View with CTG + TGT + SWP (training-context keys)
        % followed by the standard SRC / VW / CLR visualization keys.
        % CTG — multi-select category columns for training stratification
        % TGT — multi-select category columns for supervised/behavior-
        %       contrastive target(s) — same STAT-metadata-column pool as
        %       CTG (drawn from the same Origin.selectionBus.categories
        %       source below), since that's what stat2dm_cebra consumes
        %       it from. Dormant for PCA/SSM/LDA today, same as CTG/SWP
        %       are dormant for CEBRA — built generically here so any
        %       subclass can wire a listbox Callback to it later.
        % SWP — multi-select Pointer axis/axes for nested outer sweep loop
            try
                S_cat  = nex_returnSelectionMask(mdlObj.Origin.selectionBus.categories);
                catIDs = string(struct2cell(S_cat))';
                catIDs = strrep(catIDs(~strcmp(catIDs, "None")), "--", "_");
                if isempty(catIDs), catIDs = "sessionLabel_phase"; end
            catch
                catIDs = "sessionLabel_phase";
            end

            swpOpts = "None";
            if isfield(mdlObj.collector, 'Pointer') && ~isempty(mdlObj.collector.Pointer)
                try
                    ptrAxes = string(fieldnames(mdlObj.collector.Pointer.selKeys))';
                    if ~isempty(ptrAxes), swpOpts = ["None", ptrAxes]; end
                catch
                end
            end

            viewDict.CTG = catIDs;
            viewDict.TGT = catIDs;
            viewDict.SWP = swpOpts;
            viewDict.SRC = "fit";
            % nexInit_collectorView appends VW and CLR defaults
            mdlObj.collector.View = nexInit_collectorView(mdlObj, viewDict);
            mdlObj.collector.View.selections.CTG = [];   % nothing selected by default
            mdlObj.collector.View.selections.TGT = [];   % nothing selected by default
            mdlObj.collector.View.selections.SWP = 1;    % "None" selected by default
            mdlObj.domain.CTG = string.empty(1, 0);
            mdlObj.domain.TGT = string.empty(1, 0);
            mdlObj.domain.SWP = "None";

            % CTG above is only a snapshot of Origin.selectionBus.categories
            % taken right now — nothing previously kept it in sync with
            % later changes (e.g. the user selecting an additional
            % category in the parent nexObj_categorical after this figure
            % was already built). selections is the one SetObservable
            % property on nexObj_selectionBus, and it's exactly the
            % property this snapshot is read from above, so listening on
            % it and calling refreshCTG() is the same leaf-level PostSet
            % pattern already used for DF_postOp.ax → refreshPointer().
            try
                mdlObj.collector.View.Listeners.CTGSource = addlistener( ...
                    mdlObj.Origin.selectionBus.categories, 'selections', 'PostSet', ...
                    @(~,~) mdlObj.refreshCTG());
            catch err
                % Origin/selectionBus.categories unavailable (e.g. headless
                % agent reconstruction) — CTG just won't live-refresh. Was a
                % silent catch; surfaced because it's otherwise
                % indistinguishable from the listener firing but bailing
                % out inside refreshCTG() itself.
                fprintf(['[mdlObject] initViewBus: CTGSource listener NOT wired (%s) ' ...
                         '— this mdlObj''s CTG bus will not live-refresh from Origin.\n'], err.message);
            end
        end

        function refreshCTG(mdlObj)
        % Re-derive CTG's available items from Origin.selectionBus.categories
        % and update the listbox in place, preserving any still-valid
        % selection — mirrors refreshPointer()'s role for DF_postOp.ax.
        % Fired by the PostSet listener initViewBus() wires above, so
        % every Predictor-family mdlObj figure (pca, lda, logistic,
        % linear) stays in sync when the parent nexObj_categorical's
        % active categories change after this figure was already built.
        %
        % collector.View is a nexObj_selectionBus HANDLE object, not a
        % struct — isfield() on it directly always returns false (same
        % pitfall documented in nexObj/CLAUDE.md for DF_postOp), which is
        % why this used to bail out unconditionally on every call. Direct
        % property access in try/catch, same as everywhere else in this
        % codebase that touches a selectionBus instance.
            try
                lb = mdlObj.collector.View.listBoxes.CTG;
            catch
                return;   % View bus (or its CTG listbox) not built yet
            end
            if isempty(lb) || ~isvalid(lb)
                return;   % figure closed
            end

            try
                S_cat  = nex_returnSelectionMask(mdlObj.Origin.selectionBus.categories);
                catIDs = string(struct2cell(S_cat))';
                catIDs = strrep(catIDs(~strcmp(catIDs, "None")), "--", "_");
                if isempty(catIDs), catIDs = "sessionLabel_phase"; end
            catch
                return;
            end

            prevSelected = string(lb.String(lb.Value));
            lb.String = catIDs;
            lb.Max    = max(numel(catIDs), 1);
            lb.Value  = find(ismember(catIDs, prevSelected));

            mdlObj.collector.View.selKeys.CTG = catIDs;

            % TGT shares CTG's own option pool — refresh it here too, same
            % trigger. Own try/catch: most subclasses' figures don't wire a
            % TGT listbox (only CEBRA consumes domain.TGT today), so its
            % listBoxes.TGT simply doesn't exist there.
            try
                lbTGT = mdlObj.collector.View.listBoxes.TGT;
                if ~isempty(lbTGT) && isvalid(lbTGT)
                    prevSelectedTGT = string(lbTGT.String(lbTGT.Value));
                    lbTGT.String = catIDs;
                    lbTGT.Max    = max(numel(catIDs), 1);
                    lbTGT.Value  = find(ismember(catIDs, prevSelectedTGT));
                    mdlObj.collector.View.selKeys.TGT = catIDs;
                end
            catch
            end

            mdlObj.applyViewBus();
        end

        function applyViewBus(mdlObj)
        % Sync domain.CTG, domain.TGT and domain.SWP from collector.View
        % selections. SWP is multi-select (nested cross-product sweep in
        % nexAnalysis_cvPermute, e.g. region x time) — "None" is dropped
        % whenever a real axis is also selected, and left as the sole value
        % otherwise so callers can keep testing `domain.SWP == "None"`.
            if ~isfield(mdlObj.collector, 'View'), return; end
            sel = nex_returnSelectionMask(mdlObj.collector.View);
            if isfield(sel, 'CTG'), mdlObj.domain.CTG = string(sel.CTG); end
            if isfield(sel, 'TGT'), mdlObj.domain.TGT = string(sel.TGT); end
            if isfield(sel, 'SWP')
                swpSel = string(sel.SWP);
                swpSel = swpSel(swpSel ~= "None");
                if isempty(swpSel), swpSel = "None"; end
                mdlObj.domain.SWP = swpSel;
            end
        end

        function initPointerBus(mdlObj)
        % Build collector.Pointer from the model's own dfID_source axes.
        % One key per axis; values = axis tick labels for windowing at fit time.
            srcAx = struct();
            try
                srcDF = dtsIO_readDF(mdlObj.nexon, mdlObj.dfID_source, []);
                if ~isempty(srcDF) && isfield(srcDF, 'ax')
                    srcAx = srcDF.ax;
                end
            catch
            end
            if isempty(fieldnames(srcAx))
                try, srcAx = mdlObj.Origin.DF_postOp.ax; catch, end
            end

            try
                axFields = fieldnames(srcAx);
                ptrDict  = struct();
                for i = 1:numel(axFields)
                    f    = axFields{i};
                    vals = srcAx.(f);
                    if ~isempty(vals)
                        ptrDict.(f) = vals;
                    end
                end
                if ~isempty(fieldnames(ptrDict))
                    mdlObj.collector.Pointer = buildSelection(mdlObj, ptrDict);
                else
                    mdlObj.collector.Pointer = [];
                end
            catch
                mdlObj.collector.Pointer = [];
            end
        end

        function buildPointerPanel(mdlObj, panelParent, position)
        % Create a scrollable Pointer panel wired to collector.Pointer.
        % Does nothing if collector.Pointer is empty.
            if isempty(mdlObj.collector.Pointer), return; end
            BLACK = [0 0 0];
            GREEN = mdlObj.nexon.settings.Colors.cyberGreen;
            pan_ptr.ph = uipanel(panelParent, ...
                "Position",        position, ...
                "BackgroundColor", BLACK, ...
                "Scrollable",      "on", ...
                "Title",           "Pointer", ...
                "ForegroundColor", GREEN);
            mdlObj.Figure.panel_pointer = nexObj_listCfgPanel( ...
                mdlObj.nexon, pan_ptr, mdlObj.collector.Pointer, [], 10);

            % Co-registered axes (e.g. chans/unit) share positionality and
            % length, so their Pointer selections must move together.
            % nexObj_listCfgPanel wires every listbox to the same generic
            % listCfgEntryChanged, which only updates the one axis that
            % changed — override each callback to also propagate to any
            % co-indexed sibling of matching length, after the default
            % bus update runs.
            bus     = mdlObj.collector.Pointer;
            ptrKeys = fieldnames(bus.listBoxes);
            for i = 1:numel(ptrKeys)
                key = ptrKeys{i};
                lb  = bus.listBoxes.(key);
                lb.Callback = @(src, ev) mdlObj.onPointerChange(src, ev, key);
            end
        end

        function onPointerChange(mdlObj, src, ev, key)
        % Run the default Pointer bus update for `key`, then propagate its
        % new selection (positional indices) to any co-indexed sibling axis
        % whose selKeys are the same length — same length is the only
        % evidence available here that a sibling is still positionally
        % aligned with `key` (e.g. after independent pooling it may not be),
        % so mismatched lengths are skipped rather than guessed at.
        % Plain field assignment (not whole-struct replacement), so this
        % does not re-fire the selections PostSet — no reentrancy risk.
            bus = mdlObj.collector.Pointer;
            listCfgEntryChanged(src, ev, key, bus);

            if ~isfield(bus.selKeys, key), return; end
            coIdx = nexOp_coIndexPairs(bus.selKeys);
            sel   = bus.selections.(key);
            nSel  = numel(bus.selKeys.(key));
            for p = 1:numel(coIdx)
                pair = coIdx{p};
                if ~ismember(key, pair), continue; end
                for m = 1:numel(pair)
                    sib = char(pair{m});
                    if strcmp(sib, key) || ~isfield(bus.selKeys, sib), continue; end
                    if numel(bus.selKeys.(sib)) ~= nSel, continue; end
                    bus.selections.(sib) = sel;
                    if isfield(bus.listBoxes, sib) && isvalid(bus.listBoxes.(sib))
                        bus.listBoxes.(sib).Value = sel;
                    end
                end
            end
        end

        function applyHeadline(mdlObj)
            if ~isempty(mdlObj.headline) && isfield(mdlObj.Figure, 'fh') && isvalid(mdlObj.Figure.fh)
                mdlObj.Figure.fh.Name = mdlObj.headline;
            end
            if isfield(mdlObj.Figure, 'fh') && isvalid(mdlObj.Figure.fh)
                mdlObj.Figure.fh.CloseRequestFcn = @(~,~) mdlObj.closeFcn();
            end
        end

        function closeFcn(mdlObj)
        % Mirrors nexObject.closeFcn: unregister from the launcher registry
        % and close the figure. Additionally clears this mdlObj's stale
        % per-fit working data — STAT/DM/TRAIN/TEST and the nexHR reduction
        % artifacts are large arrays (and, for HR, a Python model tree) tied
        % to whatever was last compiled/fit; nothing outside this mdlObj
        % needs them once its figure is gone. cfg/domain/collector/fitPath/
        % model/RESULTS are left untouched — those are either persisted
        % config or the fit artifact itself (saveFit'd separately), not
        % per-compile working state.
            try
                figs = mdlObj.nexon.UserData.launchedFigures;
                mdlObj.nexon.UserData.launchedFigures = ...
                    figs(~cellfun(@(f) isequal(f, mdlObj), figs));
            catch
            end
            % Drop the precompile PostSet listeners on Origin's
            % selectionBus — each closure captures mdlObj itself
            % (invalidatePrecompile), which would otherwise keep mdlObj
            % (and the STAT/DM arrays cleared below) alive indefinitely via
            % Origin's listener list even after this figure is closed.
            try
                if isstruct(mdlObj.precompileListeners)
                    lf = fieldnames(mdlObj.precompileListeners);
                    for i = 1:numel(lf)
                        try, delete(mdlObj.precompileListeners.(lf{i})); catch, end
                    end
                end
            catch
            end
            mdlObj.STAT               = [];
            mdlObj.statImportedExternally = false;   % the flag only ever meant "reuse THIS STAT" -- never let it outlive it
            mdlObj.STAT_postOp        = [];
            mdlObj.DM                 = [];
            mdlObj.TRAIN              = [];
            mdlObj.TEST               = [];
            mdlObj.trainMask          = [];
            mdlObj.HR                 = [];
            mdlObj.FTR_layout         = [];
            mdlObj.precompiledAligned = [];
            mdlObj.precompileWatchersWired = false;
            try
                if isfield(mdlObj.Figure, 'fh') && isvalid(mdlObj.Figure.fh)
                    delete(mdlObj.Figure.fh);
                end
            catch
            end
        end

        function locateDataset(mlObj)

        end

        function Y = infer(mlObj, X)
        end

        function train(mlObj)
        end

        function formatSample(X, Y)
        end

        function getDesignMatrix(mdlObj)
            % train/test partition
            if ~isempty(mdlObj.trainMask)
                STAT_train = mdlObj.STAT(mdlObj.trainMask==1,:);
                STAT_test  = mdlObj.STAT(mdlObj.trainMask==0,:);
            else
                STAT_train = mdlObj.STAT;
                STAT_test  = [];
            end
            % Pooling is handled by nexOp_compileSTAT before getDesignMatrix is called.
            mdlObj.TEST.STAT  = STAT_test;
            mdlObj.TRAIN.STAT = STAT_train;
            mdlObj.TRAIN.G            = [];   % set below for a needsHR fit; stays
                                               % empty otherwise (plain dmFcn path
                                               % has no reduce/pool G companion table)
            mdlObj.FTR_blockColRanges = [];   % same -- cleared unconditionally so a
                                               % later non-needsHR fit (e.g. pMap
                                               % reconfigured back to pool-mode) doesn't
                                               % see a stale block structure from an
                                               % earlier needsHR fit

            % needsHR mdlObjs defer ALL pMap pooling to here — nexOp_compileSTAT
            % skips it entirely (TF_pooled = TF) so a reduce-mode FTR axis
            % (e.g. unit/chans) sees full temporal resolution before a
            % coexisting pool-mode axis (e.g. t) collapses it (WIP.md #3).
            % Mirrors nexAnalysis_cvPermute's own reduce-then-pool sequence
            % exactly (its "re-fit on full CTG data" step) — just on
            % STAT_train directly, no folds/SWP/permutation (SWP sweeping
            % over this already-reduced+pooled DM is fitSWPGrid's job, not
            % this method's). Admits every dmCfg format, not just
            % "supervised" — "supervised" additionally runs
            % nexOp_buildSupervisedDM's Y-encoding step; every other format
            % (e.g. "stack", SSM/PCA/UMAP/CEBRA's default) uses the
            % reduced+pooled X directly as DM, no Y step. This does mean a
            % needsHR PCA/UMAP/CEBRA mdlObj's own nexFit_*.m now runs its
            % own top-level reduction/scaling a second time on an already-
            % reduced DM — not yet reconciled for those models (SSM is the
            % only one actually wired onto this path today; see WIP.md).
            needsHR = false;
            if ~isempty(mdlObj.pMap)
                pmFields = fieldnames(mdlObj.pMap);
                needsHR  = any(arrayfun(@(i) mdlObj.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
            end
            if needsHR && ~isempty(STAT_train)
                poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
                [~, ~, blockColRanges, X_train_r, G_train] = mdlObj.fitReduce(STAT_train);
                if poolAxis ~= ""
                    [X_train_p, G_train_p] = nexOp_poolStackedDM(X_train_r, G_train, mdlObj.pMap, poolAxis);
                else
                    X_train_p = X_train_r; G_train_p = G_train;
                end
                mdlObj.FTR_blockColRanges = blockColRanges;
                mdlObj.TRAIN.G            = G_train_p;
                if strcmp(mdlObj.cfg.dmCfg.format, "supervised")
                    tVar = char(mdlObj.dfID_target);
                    nBinsY = Inf;
                    try
                        nBinsY = mdlObj.collector.Target.nBins;
                    catch
                    end
                    Y_train_raw = G_train_p.(tVar);
                    if iscell(Y_train_raw), Y_train_raw = [Y_train_raw{:}]'; end
                    [Y_train_q, edgesY] = nexOp_quantizeY(Y_train_raw, nBinsY);
                    mdlObj.DM = nexOp_buildSupervisedDM(X_train_p, Y_train_q, tVar, edgesY);
                else
                    mdlObj.DM = X_train_p;   % flat (nGroups, nFeatures) — stays
                        % 2D here even for "stack" (SSM); reshaping into real
                        % trial/time array dims (if the consumer needs that,
                        % e.g. dynamax) is that consumer's own job, using
                        % mdlObj.TRAIN.G.trialIdx/.(poolAxis) — see nexFit_ssm.m.
                end
                fprintf('[getDesignMatrix] needsHR: reduced+pooled train X %s\n', mat2str(size(X_train_p)));
                return;
            end

            % compile design matrix (ND: first dim = samples, rest = FTR axes)
            dmFcn     = str2func(sprintf("stat2dm_%s", mdlObj.cfg.dmCfg.format));
            mdlObj.DM = dmFcn(mdlObj);
            % Terminal NaN resolution: nexOp_alignCoAxes NaN-pads
            % structurally-absent canonical positions (by design, so
            % upstream pooling/cropping stays unbiased) — no fit function
            % downstream (including nexHR_fit's block-PCA, and sklearn for
            % Predictor models) handles NaN input, so it must be zero-filled
            % here, once, for every subclass's plain fit() path.
            % nexAnalysis_cvPermute does the equivalent right before each of
            % its own fit/predict calls, but a plain fit() (e.g. PCA/UMAP,
            % or LDA/logistic run without CV) never hits that treatment
            % without this. dmCfg formats differ in shape: "stack"/"batch"/
            % "regression" return DM as a plain numeric array; "supervised"
            % (stat2dm_supervised) returns a struct with the numeric array
            % at DM.X — both need the same zero-fill.
            if isnumeric(mdlObj.DM)
                mdlObj.DM(isnan(mdlObj.DM)) = 0;
            elseif isstruct(mdlObj.DM) && isfield(mdlObj.DM, 'X') && isnumeric(mdlObj.DM.X)
                mdlObj.DM.X(isnan(mdlObj.DM.X)) = 0;
            end
            % build layout then reduce (nexHR) or flatten to 2D
            mdlObj.FTR_layout = mdlObj.buildFTRLayout();
            mdlObj.initReducer();
        end

        function layout = buildFTRLayout(mdlObj)
        % Build the nexHR axis layout from TRAIN.STAT after the pool step.
        % layout(i).axID = axis name, layout(i).n = post-pool size.
        % Ordered outermost-first (= last dim in DM = highest ptr.dim value).
            layout = struct('axID', {}, 'n', {});
            if isempty(mdlObj.TRAIN.STAT), return; end
            ptr   = mdlObj.TRAIN.STAT.ptr(1);
            ax_s  = mdlObj.TRAIN.STAT.ax(1);
            dnSel = string(mdlObj.domain.DN(1));
            axNames  = string(fieldnames(ax_s))';
            ftrAxes  = axNames(axNames ~= dnSel & axNames ~= "None");
            if isempty(ftrAxes), return; end
            % dim = [] for co-indexed label axes (e.g. 'chans' on a unit DF);
            % filter them out before sorting — they have no array dimension to order.
            dimCell  = arrayfun(@(ax) ptr.(char(ax)).dim, ftrAxes, 'UniformOutput', false);
            validMask = ~cellfun(@isempty, dimCell);
            ftrAxes   = ftrAxes(validMask);
            if isempty(ftrAxes), return; end
            dims = cell2mat(dimCell(validMask));
            ns   = arrayfun(@(ax) numel(ax_s.(char(ax))), ftrAxes);
            [~, ord] = sort(dims, 'descend');   % outermost = last dim = highest
            ftrAxes  = ftrAxes(ord);
            ns       = ns(ord);
            % axVals: this axis's actual tick values (post-pool/relabel),
            % needed by nexHR_fit to derive region-aware block-PCA
            % boundaries via poolMap.getBinEdges — not just a count.
            layout   = arrayfun(@(ax, n) struct('axID', char(ax), 'n', double(n), ...
                                                 'axVals', ax_s.(char(ax))), ftrAxes, ns);
        end

        function initReducer(mdlObj)
        % Base: fit nexHR when any FTR axis has negative divsPerBin.
        % Otherwise flatten DM to 2D. Subclasses may override (SSM does).
        % dmCfg formats differ in shape: "stack"/"batch"/"regression" leave
        % DM a plain numeric array; "supervised" (stat2dm_supervised) makes
        % DM a struct {X,Y,K}. nexHR_fit/reshape only ever operate on the
        % numeric part — resolve it once here so both shapes are handled
        % identically instead of silently reducing/reshaping a struct.
            if isempty(mdlObj.DM), return; end
            isStructDM = isstruct(mdlObj.DM) && isfield(mdlObj.DM, 'X');
            if isStructDM
                X_in = mdlObj.DM.X;
            else
                X_in = mdlObj.DM;
            end
            if isempty(X_in), return; end
            layout   = mdlObj.FTR_layout;
            needsHR  = ~isempty(layout) && ~isempty(mdlObj.pMap) && ...
                any(arrayfun(@(e) isfield(mdlObj.pMap, e.axID) && ...
                                  mdlObj.pMap.(e.axID).divsPerBin < 0, layout));
            if needsHR
                useGPU = isfield(mdlObj, 'cfg') && isfield(mdlObj.cfg, 'fitCfg') && ...
                         isfield(mdlObj.cfg.fitCfg, 'entryParams') && ...
                         isfield(mdlObj.cfg.fitCfg.entryParams, 'useGPU') && ...
                         mdlObj.cfg.fitCfg.entryParams.useGPU;
                [X_out, mdlObj.HR] = nexHR_fit(X_in, layout, mdlObj.pMap, useGPU);
            else
                X_out = reshape(X_in, size(X_in, 1), []);
            end
            if isStructDM
                mdlObj.DM.X = X_out;
            else
                mdlObj.DM = X_out;
            end
        end

        function [HR, layout, blockColRanges, X_reduced, G] = fitReduce(mdlObj, STAT_fit)
        % Fit a nexHR block-PCA reduction basis on STAT_fit's RAW (pre-pool)
        % data, and return the reduced output for STAT_fit itself (avoids a
        % redundant extra applyReduce(STAT_fit,...) call at the caller).
        % CV-agnostic — "STAT_fit" is whatever the caller considers the
        % fit-on set (one CV fold's training trials, a plain fit()'s whole
        % TRAIN.STAT, anything else); this method has no notion of folds.
        % Single-FTR-axis only for now (see WIP.md #4).
        %
        % subj_internal (Nexus WIP.md #10): STAT_fit's own subject(s), a
        % real STAT column added by nexOp_compileSTAT, riding through
        % whatever fold/combo slicing already happened to produce STAT_fit.
        % 0 or 1 subject present → single nexHR_fit call, same as always,
        % just now also passing that subject to getBinEdges so region-mode
        % pooling resolves the RIGHT subject's regMap. >1 subject present
        % → nexHR_fit cannot correctly express this (one binEdges/PCA-basis
        % call, applied to every row uniformly, can't serve subjects whose
        % channel->region mapping genuinely differs) — delegate to
        % fitReduceMultiSubject_ instead, which reduces per-subject and
        % canonicalizes by region-component NAME across subjects afterward.
            subjAll = string.empty;
            if ismember('subj_internal', STAT_fit.Properties.VariableNames)
                subjAll = string(STAT_fit.subj_internal);
            end
            uniqSubjFit = unique(subjAll);
            if numel(uniqSubjFit) > 1
                [HR, layout, blockColRanges, X_reduced, G] = ...
                    mdlObj.fitReduceMultiSubject_(STAT_fit, subjAll, uniqSubjFit);
                return;
            end

            ftrAxis = char(mdlObj.domain.FTR(1));
            [X_raw, G] = nexOp_stackByFTR(STAT_fit, ftrAxis);
            % Terminal NaN resolution — same reason/placement as
            % getDesignMatrix()'s own: nexOp_alignCoAxes NaN-pads
            % structurally-absent canonical positions (by design, so
            % upstream cropping stays unbiased); no fit function downstream
            % (nexHR_fit's block-PCA included) handles NaN input. Zero-fill
            % right before it, once, same as every other path already does.
            X_raw(isnan(X_raw)) = 0;
            fprintf('[fitReduce] stacked raw X: %s (ftrAxis=%s)\n', mat2str(size(X_raw)), ftrAxis);

            % Standardize BEFORE block-PCA — nexHR_fit's own PCA whitening
            % only normalizes OUTPUT component variance, not the INPUT
            % channels feeding it, so without this a block spanning
            % channels on very different raw scales has its principal axes
            % dominated by whichever channel is loudest. Fit once, globally,
            % on the whole raw stack (same convention nexFit_pca.m/
            % nexFit_lda.m/nexFit_umap.m already use on their own flat DM)
            % — reusing mdlObj.Scaler rather than a per-block scaler, since
            % this is a single upstream normalization step, not part of
            % nexHR_fit's own per-block recursion.
            if isstruct(mdlObj.Scaler) && isfield(mdlObj.Scaler, 'model') && ~isempty(mdlObj.Scaler.model)
                mdlObj.Scaler.model = mdlObj.Scaler.model.fit(py.numpy.array(X_raw));
                X_raw = double(mdlObj.Scaler.model.transform(py.numpy.array(X_raw)));
            end

            % pMap is typically configured on whichever co-indexed sibling
            % is "primary" for binning purposes (e.g. domain.REG='chans',
            % physical channel position — what region boundaries are
            % actually defined against), not necessarily domain.FTR itself
            % (e.g. 'unit', a cross-session identity axis with no
            % meaningful position of its own to bin by, even though it's
            % what owns the real array dimension nexOp_stackByFTR just
            % resolved above — that resolution is unaffected by any of
            % this, since it goes through .ptr, not pMap). layout.axID
            % must be the PMAP KEY for nexHR_fit/nexHR_transform's own
            % isfield(pMap, current.axID) lookup to find it; layout.axVals
            % must be that primary axis's OWN values, not FTR's.
            ax0 = STAT_fit.ax(1);
            [pm_ftr, pmKey] = nexOp_resolvePMapEntry(mdlObj.pMap, ftrAxis, ax0);
            if isempty(pm_ftr)
                error('mdlObject:fitReduce:noPMapEntry', ...
                    'FTR axis "%s" has no pMap entry, directly or via a co-indexed sibling.', ftrAxis);
            end
            layout = struct('axID', pmKey, 'n', double(numel(ax0.(pmKey))), ...
                             'axVals', ax0.(pmKey));

            useGPU = isfield(mdlObj, 'cfg') && isfield(mdlObj.cfg, 'fitCfg') && ...
                     isfield(mdlObj.cfg.fitCfg, 'entryParams') && ...
                     isfield(mdlObj.cfg.fitCfg.entryParams, 'useGPU') && ...
                     mdlObj.cfg.fitCfg.entryParams.useGPU;
            [X_reduced, HR] = nexHR_fit(X_raw, layout, mdlObj.pMap, useGPU, uniqSubjFit);
            fprintf('[fitReduce] reduced X: %s\n', mat2str(size(X_reduced)));

            % Side effect, mirroring initReducer()'s own convention: leaves
            % mdlObj.HR/.FTR_layout set to whichever fitReduce call ran most
            % recently, so flattenInput()/inference-time consumers see a
            % usable model without the caller having to wire this manually.
            % In a CV loop that's the final full-data re-fit (see nexAnalysis_
            % cvPermute's own "re-fit on full CTG data" step), same as today.
            mdlObj.HR         = HR;
            mdlObj.FTR_layout = layout;

            blockColRanges = nexHR_blockColRanges(pm_ftr, layout.axVals, size(X_raw, 1), uniqSubjFit);
            fprintf('[fitReduce] %d block(s): %s\n', numel(blockColRanges), ...
                    strjoin(arrayfun(@(r) sprintf('%s[%d:%d]', string(r.label), r.cols(1), r.cols(end)), ...
                                      blockColRanges, 'UniformOutput', false), ', '));
        end

        function [HR, layout, blockColRanges, X_reduced, G] = fitReduceMultiSubject_(mdlObj, STAT_fit, subjAll, uniqSubjFit)
        % Case 3 of Nexus WIP.md #10 — STAT_fit spans more than one subject
        % under one needsHR fit (CTG doesn't include subject). nexHR_fit
        % computes one set of block boundaries and fits one PCA basis per
        % block, once, for whatever it's handed — it has no notion of a
        % per-row-varying block structure, so a single call can't correctly
        % serve subjects whose channel->region mapping genuinely differs
        % (subject A's channels 1-10 could be STN while subject B's
        % channels 1-10 are HY). Fix: run fitReduce separately per subject
        % (own regMap, own block boundaries, own fitted PCA basis per
        % region), then canonicalize the per-subject output across subjects
        % by REGION-COMPONENT NAME (e.g. "STN_pc1") instead of raw column
        % index — the same hierarchical per-subject-then-across-subjects
        % pattern nexOp_compileSTAT already uses for raw REG identity, one
        % tier higher, after reduction instead of before it.
        %
        % One real wrinkle: nexHR_fit clamps each block's component count
        % to that subject's own available units/samples, so the SAME
        % region can come out with a different component count per subject
        % (e.g. STN_pc1-3 for one subject, STN_pc1-2 for another). Handled
        % by unioning labels and leaving any subject's missing column NaN
        % — same convention nexAnalysis_cvPermute.m's own Wfull
        % consolidation already established (NaN, not zero or drop, so
        % every NaN-aware downstream consumer treats it as "no data").
            nSubj = numel(uniqSubjFit);
            X_perSubj      = cell(1, nSubj);
            labels_perSubj = cell(1, nSubj);
            G_perSubj      = cell(1, nSubj);
            HR_perSubj     = cell(1, nSubj);
            layout_perSubj = cell(1, nSubj);
            blocks_perSubj = cell(1, nSubj);

            for si = 1:nSubj
                STAT_si = STAT_fit(subjAll == uniqSubjFit(si), :);
                [HR_si, layout_si, blocks_si, X_si, G_si] = mdlObj.fitReduce(STAT_si);
                lbl = strings(1, size(X_si, 2));
                for b = 1:numel(blocks_si)
                    cols = blocks_si(b).cols;
                    % Component index WITHIN this block appended so
                    % different components of the SAME region stay
                    % distinct columns after the union below — the union
                    % is only ever applied to the label, never merges
                    % different components of one region together.
                    for c = 1:numel(cols)
                        lbl(cols(c)) = sprintf('%s_pc%d', string(blocks_si(b).label), c);
                    end
                end
                layout_si.colLabels = lbl;   % so applyReduceMultiSubject_ can relabel without re-deriving blockColRanges
                X_perSubj{si}      = X_si;
                G_perSubj{si}      = G_si;
                HR_perSubj{si}     = HR_si;
                layout_perSubj{si} = layout_si;
                blocks_perSubj{si} = blocks_si;
                labels_perSubj{si} = lbl;
            end

            unionLabels = unique([labels_perSubj{:}], 'stable');
            nCols       = numel(unionLabels);
            nRowsTotal  = sum(cellfun(@(x) size(x,1), X_perSubj));
            X_reduced   = nan(nRowsTotal, nCols);
            G           = table();
            rowStart    = 1;
            for si = 1:nSubj
                nRows_si = size(X_perSubj{si}, 1);
                rowIdx   = rowStart : (rowStart + nRows_si - 1);
                [~, colIdx] = ismember(labels_perSubj{si}, unionLabels);
                X_reduced(rowIdx, colIdx) = X_perSubj{si};
                Gsi = G_perSubj{si};
                if istable(Gsi) && ~isempty(Gsi)
                    if isempty(G), G = Gsi; else, G = [G; Gsi]; end %#ok<AGROW>
                end
                rowStart = rowStart + nRows_si;
            end

            % No single coherent HR/layout exists once subjects were reduced
            % separately with their own bases — carry the per-subject
            % structs forward instead of picking one arbitrarily and
            % silently mislabeling the rest. applyReduce detects this shape
            % (bySubject=true) and dispatches to applyReduceMultiSubject_
            % the same way fitReduce dispatches here.
            HR     = struct('bySubject', true, 'subjects', uniqSubjFit, 'perSubject', {HR_perSubj});
            layout = struct('bySubject', true, 'subjects', uniqSubjFit, 'perSubject', {layout_perSubj}, ...
                             'unionLabels', unionLabels);

            % blockColRanges, unlike HR/layout, is purely descriptive column
            % metadata (.label/.cols into X_reduced) — no model state, so no
            % need to wrap it per-subject. Every real consumer
            % (resolveSWPMaskHR's SWP column-mask lookup in
            % nexAnalysis_cvPermute.m, nexAudit_blockVariance, and
            % nexAnalysis_cvPermute.m's R.featureLabels construction, Nexus
            % WIP.md #11) already expects the flat .label/.cols shape
            % fitReduce's single-subject path returns, and none of them
            % check a .bySubject discriminator on blockColRanges
            % specifically (only HR.bySubject/fitSentinel.bySubject are
            % ever read — confirmed codebase-wide) — so returning the
            % wrapper here silently broke all of them whenever a fit call's
            % STAT spanned multiple subjects not otherwise separated by
            % CTG/SWP. Build the flat shape directly over the UNION
            % columns: group by base region/band name (stripping the
            % "_pcN" suffix used to keep different components of one region
            % distinct in the union), collecting ALL matching columns per
            % label via find(...) rather than assuming a contiguous run —
            % unique(...,'stable') can append a later subject's EXTRA
            % component for an already-seen region after a different
            % region's label was already inserted, which would otherwise
            % split one region's columns into non-adjacent groups.
            baseLabels     = regexprep(unionLabels, '_pc\d+$', '');
            uniqueBase     = unique(baseLabels, 'stable');
            blockColRanges = struct('label', {}, 'cols', {});
            for b = 1:numel(uniqueBase)
                blockColRanges(b).label = uniqueBase(b);
                blockColRanges(b).cols  = find(baseLabels == uniqueBase(b));
            end

            mdlObj.HR         = HR;
            mdlObj.FTR_layout = layout;
            fprintf('[fitReduce] multi-subject: %d subject(s), %d union region-component column(s)\n', ...
                    nSubj, nCols);
        end

        function [X_reduced, G] = applyReduce(mdlObj, STAT, HR, layout)
        % Apply an already-fitted nexHR model tree (from fitReduce) to
        % STAT's raw data. CV-agnostic — reusable for a fold's held-out
        % trials, a plain fit()'s test split, or a future inference path.
            if isstruct(HR) && isfield(HR, 'bySubject') && HR.bySubject
                [X_reduced, G] = mdlObj.applyReduceMultiSubject_(STAT, HR, layout);
                return;
            end
            % subjID — MUST match whatever subjID fitReduce resolved to
            % produce this HR/layout (see nexHR_transform's own comment on
            % why a mismatch here silently shifts block boundaries). Since
            % this is the single-subject branch, STAT has 0 or 1 subject.
            subjID = string.empty;
            if ismember('subj_internal', STAT.Properties.VariableNames)
                subjID = unique(string(STAT.subj_internal));
            end
            ftrAxis = char(mdlObj.domain.FTR(1));
            [X_raw, G] = nexOp_stackByFTR(STAT, ftrAxis);
            % Terminal NaN resolution — see fitReduce's own comment.
            X_raw(isnan(X_raw)) = 0;
            fprintf('[applyReduce] stacked raw X: %s (ftrAxis=%s)\n', mat2str(size(X_raw)), ftrAxis);
            % Apply the SAME fitted scaler fitReduce used (transform only —
            % never re-fit here, or train/test would be standardized
            % against different statistics). See fitReduce's own comment.
            if isstruct(mdlObj.Scaler) && isfield(mdlObj.Scaler, 'model') && ~isempty(mdlObj.Scaler.model)
                X_raw = double(mdlObj.Scaler.model.transform(py.numpy.array(X_raw)));
            end
            X_reduced = nexHR_transform(X_raw, layout, mdlObj.pMap, HR, subjID);
            fprintf('[applyReduce] reduced X: %s\n', mat2str(size(X_reduced)));
        end

        function [X_reduced, G] = applyReduceMultiSubject_(mdlObj, STAT, HR, layout)
        % Case 3 counterpart to fitReduceMultiSubject_ — see that method's
        % comment and Nexus WIP.md #10. Splits STAT (e.g. a fold's test
        % set) by subject, transforms each with ITS OWN fitted basis
        % (HR.perSubject{si}/layout.perSubject{si}), then lands every
        % subject's output into the SAME union region-component column
        % space fitReduce already established (layout.unionLabels). A
        % subject present in STAT but not seen during fitReduce shouldn't
        % happen in practice (train/test share one CTG combo's subject
        % population) — skipped with a warning, left all-NaN, rather than
        % erroring.
            subjAll = string.empty;
            if ismember('subj_internal', STAT.Properties.VariableNames)
                subjAll = string(STAT.subj_internal);
            end
            unionLabels = layout.unionLabels;
            X_reduced   = nan(height(STAT), numel(unionLabels));
            G           = table();
            ftrAxis     = char(mdlObj.domain.FTR(1));
            uniqSubjHere = unique(subjAll);
            if isempty(uniqSubjHere) && height(STAT) > 0
                % No subj_internal to resolve against (e.g. a single raw
                % trial reconstructed via flattenInput, which doesn't carry
                % that STAT column) — fail loudly rather than silently
                % returning an all-NaN X_reduced, which would otherwise
                % look like a legitimate (if useless) result.
                error('mdlObject:applyReduceMultiSubject_:noSubjInfo', ...
                    ['This fit spans multiple subjects (%s) but the STAT being ' ...
                     'transformed has no subj_internal column to resolve which ' ...
                     'subject''s basis to apply — known gap, see Nexus WIP.md #10.'], ...
                    strjoin(string(HR.subjects), ', '));
            end
            for si = 1:numel(uniqSubjHere)
                s = uniqSubjHere(si);
                trainIdx = find(HR.subjects == s, 1);
                if isempty(trainIdx)
                    fprintf('[applyReduce] subject %s not seen during fitReduce — leaving its rows NaN.\n', s);
                    continue;
                end
                mask_si = (subjAll == s);
                STAT_si = STAT(mask_si, :);
                [X_raw_si, G_si] = nexOp_stackByFTR(STAT_si, ftrAxis);
                X_raw_si(isnan(X_raw_si)) = 0;
                X_si = nexHR_transform(X_raw_si, layout.perSubject{trainIdx}, mdlObj.pMap, HR.perSubject{trainIdx}, s);
                lbl_si = layout.perSubject{trainIdx}.colLabels;
                [~, colIdx] = ismember(lbl_si, unionLabels);
                X_reduced(mask_si, colIdx) = X_si;
                if istable(G_si) && ~isempty(G_si)
                    if isempty(G), G = G_si; else, G = [G; G_si]; end %#ok<AGROW>
                end
            end
            fprintf('[applyReduce] multi-subject: %s\n', mat2str(size(X_reduced)));
        end

        function [X_flat, G_flat] = flattenInput(mdlObj, DF_X)
        % Convert a raw (post-pool, D1-first) ND DF to a 2D feature matrix.
        % Uses nexHR_transform when an HR model is fitted; otherwise plain reshape.
        % Called at the top of every subclass transform — subclasses need not know
        % whether nexHR was used.
        %
        % G_flat (2nd output, optional) — the needsHR branch's own
        % trialIdx/poolAxis-bin companion table (nexOp_stackByFTR's /
        % nexOp_poolStackedDM's G), empty for every other branch. Existing
        % callers (mdlObj_lda/mdlObj_umap) request only X_flat and are
        % unaffected; a caller whose dynamics depend on real trial/time
        % array shape (mdlObj_ssm) needs this to reshape X_flat back.
            G_flat = [];
            needsHR = false;
            if ~isempty(mdlObj.pMap)
                pmFields = fieldnames(mdlObj.pMap);
                needsHR  = any(arrayfun(@(i) mdlObj.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
            end
            if needsHR && ~isempty(mdlObj.HR)
                % DF_X here is still raw/unpooled (nexOp_compileSTAT skips
                % pooling entirely for needsHR — WIP.md #3), so it must go
                % through the SAME reduce-then-pool sequence getDesignMatrix()
                % used to fit mdlObj.HR, not the raw nexHR_transform call
                % below — that call assumes DF_X is already at the pooled
                % granularity HR was actually fitted at, which is no longer
                % true once pooling is deferred this far. Admits every dmCfg
                % format, not just "supervised" — this block is X-only (no
                % Y-encoding), so the old format gate was never actually
                % load-bearing here; it just also blocked SSM's "stack"
                % format for no reason. applyReduce needs a
                % STAT-shaped table (nexOp_stackByFTR indexes STAT.df{i} as a
                % cell) — DF_X is a single-trial struct with df as a plain
                % array, so wrap it the same way STAT's own df column is
                % stored before reconstructing the table.
                row = DF_X;
                row.df = {DF_X.df};
                STAT_1 = struct2table(row);
                [X_r, G_r] = mdlObj.applyReduce(STAT_1, mdlObj.HR, mdlObj.FTR_layout);
                poolAxis = nexOp_resolvePoolAxis(mdlObj.pMap);
                if poolAxis ~= ""
                    X_flat = nexOp_poolStackedDM(X_r, G_r, mdlObj.pMap, poolAxis);
                else
                    X_flat = X_r;
                end
                return;
            end
            X = DF_X.df;
            if ~isempty(mdlObj.HR)
                if mdlObj.domain.DN(1) == "None"
                    X = reshape(X, [1, size(X)]);  % single-trial: add N_ctx=1 to match fit shape
                end
                X_flat = nexHR_transform(X, mdlObj.FTR_layout, mdlObj.pMap, mdlObj.HR);
            else
                X_flat = reshape(X, size(X, 1), []);
            end
        end

        function importSTATFrom(mdlObj, otherMdlObj)
        % Reuse an already-compiled STAT from ANOTHER live mdlObj (same
        % session) -- skips compileSTAT() entirely, which is often the
        % genuinely expensive step (not fitting itself) for a large DTS.
        % No shape requirement beyond "a STAT-shaped table" -- compiling
        % once off an mdlObj_lda and reusing it directly in a fresh
        % mdlObj_lme is the motivating case, but this works for any two
        % mdlObjs sharing the same dfID_source/selection.
            if isempty(otherMdlObj.STAT)
                error('mdlObject:importSTATFrom:empty', ...
                    'otherMdlObj.STAT is empty -- nothing to import.');
            end
            mdlObj.STAT = otherMdlObj.STAT;
            mdlObj.statImportedExternally = true;
            mdlObj.refreshPointerFromSTAT_();
            fprintf('[mdlObject.importSTATFrom] imported %d rows from %s.\n', ...
                height(mdlObj.STAT), class(otherMdlObj));
        end

        function saveSTAT(mdlObj, filePath)
        % Persist mdlObj.STAT to a .mat file, for reuse across sessions
        % (importSTATFrom() above only works while both objects are
        % still live in the SAME session). ptr is NOT saved -- same
        % convention nexOp_saveResult.m already uses for RESULTS tables:
        % it's fully deterministic from df+ax (nexInit_axisPointer),
        % reconstructed on load instead of persisted, avoiding any
        % handle-class (nexObj_ptr) serialization/version fragility.
            STAT = mdlObj.STAT;
            if isempty(STAT)
                error('mdlObject:saveSTAT:empty', 'mdlObj.STAT is empty -- nothing to save.');
            end
            if ismember('ptr', STAT.Properties.VariableNames)
                STAT = removevars(STAT, 'ptr');
            end
            save(filePath, 'STAT', '-v7.3');
            fprintf('[mdlObject.saveSTAT] %d rows -> %s\n', height(STAT), filePath);
        end

        function loadSTAT(mdlObj, filePath)
        % Load a STAT table saved via saveSTAT() into mdlObj.STAT. Works
        % for a STAT saved by a DIFFERENT mdlObj (e.g. mdlObj_lda's STAT,
        % reused directly by a fresh mdlObj_lme) -- same motivating case
        % as importSTATFrom(), just surviving a session restart / shared
        % across machines. ptr is reconstructed per row via
        % nexInit_axisPointer(df, ax) -- STAT.ax may be stored as either
        % a cell column or a struct array depending on producer (same
        % dual-shape handling buildLongSTAT.m's own resolveFeatureAxis
        % uses); the reconstructed ptr column is built as a handle-object
        % array (vertcat of nexObj_ptr), matching mdlObject's own native
        % compileSTAT() output shape (nexOp_stackSTAT.m indexes
        % STAT.ptr(i) directly, never STAT.ptr{i}) -- NOT a cell, unlike
        % nexOp_loadResult.m's RESULTS-table convention, which is a
        % separate contract this intentionally does not reuse.
            S    = load(filePath, 'STAT');
            STAT = S.STAT;
            isAxCell = iscell(STAT.ax);
            ptrList  = cell(height(STAT), 1);
            for i = 1:height(STAT)
                if isAxCell, ax_i = STAT.ax{i}; else, ax_i = STAT.ax(i); end
                try
                    ptrList{i} = nexInit_axisPointer(STAT.df{i}, ax_i);
                catch
                    ptrList{i} = [];
                end
            end
            STAT.ptr = vertcat(ptrList{:});
            mdlObj.STAT = STAT;
            mdlObj.statImportedExternally = true;
            mdlObj.refreshPointerFromSTAT_();
            fprintf('[mdlObject.loadSTAT] %d rows <- %s\n', height(STAT), filePath);
        end

        function refreshPointerFromSTAT_(mdlObj)
        % Seed/refresh collector.Pointer's axis OPTIONS (not just the
        % selection) from mdlObj.STAT's own first row -- the same "give me
        % a full view of the STAT elements" guarantee precompileSTAT()
        % provides via nexOp_compileSTAT's internal refreshPointerFromPool
        % call, just reached differently here: that path pools a RAW
        % per-trial TF through the current pMap as a preview (nothing
        % compiled yet); importSTATFrom()/loadSTAT() already have a fully
        % compiled, already-pooled STAT in hand, so this seeds Pointer
        % straight from its real axis values instead -- no pooling preview
        % needed. refreshPointerAxes_ (the shared primitive both
        % refreshPointer and refreshPointerFromPool build on) updates
        % existing Pointer keys' value lists/selections AND any already-
        % open listbox widgets in place; initPointerBus() is the fallback
        % when Pointer hasn't been built at all yet -- same two-branch
        % guard nexObj_bar.applySRC/nexObj_violin.applySRC already use for
        % the analogous nexObject-side case.
            if isempty(mdlObj.STAT) || height(mdlObj.STAT) == 0, return; end
            if ~ismember('ax', mdlObj.STAT.Properties.VariableNames), return; end
            if iscell(mdlObj.STAT.ax), ax0 = mdlObj.STAT.ax{1}; else, ax0 = mdlObj.STAT.ax(1); end
            if ~isfield(mdlObj.collector, 'Pointer') || isempty(mdlObj.collector.Pointer)
                mdlObj.initPointerBus();
            else
                mdlObj.refreshPointerAxes_(ax0);
            end
        end

        function fit(mdlObj)
            % Thin wrapper -- fitSWPGrid is the canonical fit path now (CTG
            % outer x SWP inner grid, one cell when both are empty/"None").
            % See fitSWPGrid()'s own docstring.
            mdlObj.fitSWPGrid();
        end

        function fitSWPGrid(mdlObj)
        % Generalized fit(): wraps compileSTAT/getDesignMatrix/cfg.fitCfg.fcn
        % in two nested outer loops -- CTG (domain.CTG combos) outer, SWP
        % (collector.View.SWP's selected axes, multi-select -- see
        % applyViewBus's own comment) inner, full Cartesian product across
        % however many SWP axes are selected -- storing one independently-
        % fit child per (CTG combo x SWP combo) cell in mdlObj.comboFits.
        % Degenerates to exactly the old single-model fit() body when
        % domain.CTG has no valid columns AND SWP is "None": one cell, same
        % end-state DM/W/model as calling getDesignMatrix()+cfg.fitCfg.fcn()
        % directly.
        %
        % fitByCombo (CTG-only, no SWP) is retired in place, not deleted or
        % called anymore -- the CTG-outer loop below is its direct
        % descendant, carrying over its child-construction skeleton
        % unchanged (predictorID special case, inherited domain/pMap/cfg/
        % collector/fitSentinel, STAT slice via nexOp_matchComboRow, the
        % headless-suppression onCleanup guard).
        %
        % Per-axis SWP resolution/narrowing is ported from
        % nexAnalysis_cvPermute.m's own multi-axis sweep (its section 4
        % swpAxes / resolveSWPMaskHR / sliceSWPCombo), generalized rather
        % than re-derived, via the shared nexOp_resolveSWPAxis/
        % nexOp_sliceSTAT/nexOp_matchesSWPValue/nexOp_swpLinToSubs helpers.
        % Two regimes, decided ONCE per CTG combo by whether this mdlObj is
        % needsHR (see getDesignMatrix's own needsHR check):
        %   - needsHR: getDesignMatrix() runs ONCE on the combo's full STAT
        %     (the expensive block-PCA reduce+pool step), then EVERY SWP
        %     axis just MASKS that one already-built DM/TRAIN.G -- "ftr"
        %     mode (the axis IS the reduce-mode FTR axis) masks COLUMNS via
        %     FTR_blockColRanges; every other axis (the deferred pool-mode
        %     axis, or any other raw axis -- nexOp_stackByFTR folds every
        %     non-FTR axis into its own TRAIN.G column) masks ROWS via
        %     TRAIN.G.(axisID)==val. No re-reduction per SWP combo.
        %   - not needsHR: there's no reduce/pool step to reuse, so every
        %     SWP axis is "raw" -- chain-slice raw STAT by dimension
        %     (nexOp_sliceSTAT) for every selected axis, one axis at a
        %     time, exactly mirroring cvPermute's own multi-axis
        %     sliceSWPCombo body, then run getDesignMatrix() once per
        %     resulting grid cell.
        %
        % KNOWN GAP: scaleApply_transform's per-DTS-row combo lookup
        % (nexOp_matchComboRow against comboFits(k).key) only matches on
        % CTG -- when SWP produces multiple children per CTG combo,
        % inference-time row->child matching doesn't yet disambiguate
        % between them. Not addressed here; comboFits(k).key is
        % deliberately kept CTG-only (nexOp_matchComboRow treats any key
        % field absent from a row's own columns as "can't match" -- adding
        % swpVal into key would break that match for every row, not just
        % fail to disambiguate). swpVal is carried as its own separate
        % field instead.
            if mdlObj.statImportedExternally
                fprintf(['[mdlObject.fitSWPGrid] reusing externally-imported STAT ' ...
                         '(%d rows) -- skipping compileSTAT().\n'], height(mdlObj.STAT));
            else
                mdlObj.compileSTAT();
            end

            ctgCols  = string(mdlObj.domain.CTG);
            validCTG = ctgCols(ismember(ctgCols, string(mdlObj.STAT.Properties.VariableNames)));

            swpIDs = string.empty;
            if isfield(mdlObj.domain, 'SWP')
                allSwp = string(mdlObj.domain.SWP);
                swpIDs = allSwp(allSwp ~= "" & allSwp ~= "None");
            end

            if isempty(validCTG) && isempty(swpIDs)
                % Degenerate case -- identical to the old single-model fit() body.
                mdlObj.comboFits = struct('key', {}, 'child', {}, 'swpVal', {});
                mdlObj.getDesignMatrix();
                mdlObj.cfg.fitCfg.fcn(mdlObj, mdlObj.cfg.fitCfg.entryParams);
                if ~isempty(mdlObj.Predictor) && ~isequal(mdlObj, mdlObj.Predictor)
                    mdlObj.Predictor.trainMask = mdlObj.trainMask;
                    mdlObj.Predictor.fit();
                end
                mdlObj.DM = [];
                return;
            end

            if isempty(validCTG)
                nCombos = 1;
            else
                comboTbl = unique(mdlObj.STAT(:, cellstr(validCTG)), 'rows');
                nCombos  = height(comboTbl);
            end
            fprintf('[mdlObject] fitSWPGrid: %d CTG combo(s) x SWP=[%s]\n', ...
                    nCombos, strjoin(swpIDs, ", "));

            initFcn = str2func(class(mdlObj));
            nexon   = mdlObj.nexon;
            wasHeadless = isfield(nexon.settings, 'headless') && nexon.settings.headless;
            nexon.settings.headless = true;
            restoreHeadless = onCleanup(@() mdlObject_restoreHeadless(nexon, wasHeadless)); %#ok<NASGU>

            newGridFits = struct('key', {}, 'child', {}, 'swpVal', {});
            for ci = 1:nCombos
                if isempty(validCTG)
                    comboKey = struct();
                    mask     = true(height(mdlObj.STAT), 1);
                else
                    comboKey = table2struct(comboTbl(ci, :));
                    mask     = nexOp_matchComboRow(mdlObj.STAT, comboKey);
                end

                child = mdlObject_initGridChild(mdlObj, initFcn);
                child.STAT      = mdlObj.STAT(mask, :);
                child.trainMask = true(height(child.STAT), 1);

                if isempty(swpIDs)
                    % No SWP -- one cell for this combo, identical to
                    % fitByCombo's own per-combo body.
                    child.getDesignMatrix();
                    child.cfg.fitCfg.fcn(child, child.cfg.fitCfg.entryParams);
                    child.DM = [];
                    newGridFits(end+1) = struct('key', comboKey, 'child', child, 'swpVal', struct()); %#ok<AGROW>
                    fprintf('[mdlObject] fitSWPGrid: combo %d/%d (%d trial(s)) fit\n', ...
                            ci, nCombos, height(child.STAT));
                    continue;
                end

                needsHR = false;
                if ~isempty(child.pMap)
                    pmFields = fieldnames(child.pMap);
                    needsHR  = any(arrayfun(@(i) child.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
                end

                swpAxes = struct('id', {}, 'vals', {}, 'rangeLabel', {}, 'mode', {}, 'dim', {}, 'n', {});
                for a = 1:numel(swpIDs)
                    [vals_a, rangeLabel_a, mode_a, dim_a] = nexOp_resolveSWPAxis(child, child.STAT, swpIDs(a));
                    swpAxes(end+1) = struct('id', swpIDs(a), 'vals', vals_a, 'rangeLabel', rangeLabel_a, ...
                                             'mode', mode_a, 'dim', dim_a, 'n', numel(vals_a)); %#ok<AGROW>
                end
                nPerAxis = [swpAxes.n];
                nSwp     = prod(nPerAxis);

                if ~needsHR
                    % No reduce/pool step to reuse -- every axis is "raw".
                    % Chain-slice raw STAT by dimension for every selected
                    % axis, then run getDesignMatrix() once per cell --
                    % mirrors cvPermute's own multi-axis sliceSWPCombo.
                    for si = 1:nSwp
                        subs       = nexOp_swpLinToSubs(si, nPerAxis);
                        grandchild = mdlObject_initGridChild(mdlObj, initFcn);
                        grandchild.STAT      = child.STAT;
                        comboParts = strings(1, numel(swpAxes));
                        swpValStruct = struct();
                        for a = 1:numel(swpAxes)
                            val    = swpAxes(a).vals(subs(a));
                            raw    = grandchild.STAT.ax(1).(char(swpAxes(a).id));
                            swpIdx = find(nexOp_matchesSWPValue(raw, val));
                            grandchild.STAT = nexOp_sliceSTAT(grandchild.STAT, swpAxes(a).dim, swpIdx);
                            comboParts(a)   = sprintf('%s=%s', swpAxes(a).id, string(val));
                            swpValStruct.(matlab.lang.makeValidName(char(swpAxes(a).id))) = swpAxes(a).rangeLabel(subs(a));
                        end
                        grandchild.trainMask = true(height(grandchild.STAT), 1);
                        grandchild.getDesignMatrix();
                        grandchild.cfg.fitCfg.fcn(grandchild, grandchild.cfg.fitCfg.entryParams);
                        grandchild.DM = [];
                        newGridFits(end+1) = struct('key', comboKey, 'child', grandchild, 'swpVal', swpValStruct); %#ok<AGROW>
                        fprintf('[mdlObject] fitSWPGrid: combo %d/%d, SWP %s fit\n', ...
                                ci, nCombos, strjoin(comboParts, ', '));
                    end
                    continue;
                end

                % needsHR: reduce+pool ONCE on this combo's full STAT (the
                % expensive step), then mask the already-built DM per SWP
                % combo instead of re-reducing per combo.
                child.getDesignMatrix();
                baseDM             = child.DM;
                baseG              = child.TRAIN.G;
                baseBlockColRanges = child.FTR_blockColRanges;

                for si = 1:nSwp
                    subs = nexOp_swpLinToSubs(si, nPerAxis);
                    cols = true(1, size(baseDM, 2));
                    rows = true(height(baseG), 1);
                    comboParts   = strings(1, numel(swpAxes));
                    swpValStruct = struct();
                    skip = false;
                    for a = 1:numel(swpAxes)
                        val = swpAxes(a).vals(subs(a));
                        if swpAxes(a).mode == "ftr"
                            bi = find(strcmp(string({baseBlockColRanges.label}), string(val)), 1);
                            if isempty(bi)
                                warning('[mdlObject] fitSWPGrid: SWP value "%s" matched no FTR block -- skipping cell.', string(val));
                                skip = true;
                                break;
                            end
                            colMask = false(1, size(baseDM, 2));
                            colMask(baseBlockColRanges(bi).cols) = true;
                            cols = cols & colMask;
                        else
                            % "pool", or any other raw axis -- nexOp_stackByFTR
                            % folds every non-FTR axis into its own TRAIN.G
                            % column, so this masks rows the same way
                            % regardless of which of those two it is.
                            rows = rows & (baseG.(char(swpAxes(a).id)) == val);
                        end
                        comboParts(a)   = sprintf('%s=%s', swpAxes(a).id, string(val));
                        swpValStruct.(matlab.lang.makeValidName(char(swpAxes(a).id))) = swpAxes(a).rangeLabel(subs(a));
                    end
                    if skip, continue; end

                    grandchild = mdlObject_initGridChild(mdlObj, initFcn);
                    grandchild.STAT      = child.STAT;
                    grandchild.trainMask = child.trainMask;
                    grandchild.DM        = baseDM(rows, cols);
                    grandchild.TRAIN.G   = baseG(rows, :);
                    % Remap surviving FTR blocks to LOCAL column indices --
                    % baseBlockColRanges indexes the FULL multi-block
                    % baseDM, not grandchild's own narrowed DM.
                    keptBlocks = struct('label', {}, 'cols', {});
                    colOffset  = 0;
                    for bi = 1:numel(baseBlockColRanges)
                        bcols = baseBlockColRanges(bi).cols;
                        bcols = bcols(ismember(bcols, find(cols)));
                        if isempty(bcols), continue; end
                        keptBlocks(end+1) = struct('label', baseBlockColRanges(bi).label, ...
                                                    'cols', colOffset + (1:numel(bcols))); %#ok<AGROW>
                        colOffset = colOffset + numel(bcols);
                    end
                    grandchild.FTR_blockColRanges = keptBlocks;

                    grandchild.cfg.fitCfg.fcn(grandchild, grandchild.cfg.fitCfg.entryParams);
                    grandchild.DM = [];
                    newGridFits(end+1) = struct('key', comboKey, 'child', grandchild, 'swpVal', swpValStruct); %#ok<AGROW>
                    fprintf('[mdlObject] fitSWPGrid: combo %d/%d, SWP %s (%dx%d) fit\n', ...
                            ci, nCombos, strjoin(comboParts, ', '), nnz(rows), nnz(cols));
                end
            end

            mdlObj.comboFits = newGridFits;
            mdlObj.DM = [];
        end

        function fitByCombo(mdlObj, validCTG)
        % One independently-fit child mdlObj per unique domain.CTG
        % combination present in STAT — mirrors crossValidate()'s own
        % per-fold child-array pattern (mdlObj.CV), keyed by CTG combo
        % instead of fold, and reuses nexAnalysis_cvPermute's own combo-
        % enumeration convention (unique(STAT(:,validCTG),'rows')) so
        % combos partition identically to how cvPermute already groups CTG
        % results. Replaces fit() outright whenever domain.CTG names real
        % STAT columns — see fit() above; not meant to be called directly
        % with a STAT that hasn't just been compiled.
        %
        % Each child gets this mdlObj's domain/pMap/cfg (so it fits under
        % the exact same feature/pooling/kernel configuration) and its own
        % STAT slice, DM, and fitted model/weights. scaleApply_transform
        % later picks the right child per DTS row via nexOp_matchComboRow
        % against each child's stored combo key (comboFits(k).key),
        % skipping any row that matches none of them — see there.
            comboTbl = unique(mdlObj.STAT(:, cellstr(validCTG)), 'rows');
            nCombos  = height(comboTbl);
            fprintf('[mdlObject] fitByCombo: %d combo(s) over %s\n', ...
                    nCombos, strjoin(validCTG, ', '));

            initFcn = str2func(class(mdlObj));
            nexon   = mdlObj.nexon;
            % Suppress each child's own interactive figure — mdlObject's
            % base constructor builds one unconditionally unless
            % nexon.settings.headless is set, and nexon is the SAME shared
            % handle for every child, so this has to be toggled off around
            % construction and restored after, not passed as a per-call
            % override (there isn't one). crossValidate()'s own child
            % construction doesn't do this — N popped-up figures for N
            % folds — deliberately not repeated here for potentially many
            % more combos.
            wasHeadless = isfield(nexon.settings, 'headless') && nexon.settings.headless;
            nexon.settings.headless = true;
            % onCleanup, not try/catch/rethrow -- a Ctrl-C interrupt during
            % any child's fit (e.g. a long-running fitlme call) is NOT a
            % catchable MException, so it skips straight past a catch
            % block's restore line, leaving nexon.settings.headless stuck
            % at true for the rest of the session (confirmed directly:
            % every mdlObj-sourced viewer constructed afterward silently
            % skipped its own buildFigure() call, looking like it "never
            % generated" with no error at all). onCleanup objects run on
            % ANY exit from this scope -- normal return, thrown error, or
            % user interrupt -- so restoration is unconditional.
            restoreHeadless = onCleanup(@() mdlObject_restoreHeadless(nexon, wasHeadless));
            newComboFits = struct('key', {}, 'child', {});
            for ci = 1:nCombos
                    key  = table2struct(comboTbl(ci, :));
                    mask = nexOp_matchComboRow(mdlObj.STAT, key);
                    if strcmpi(mdlObj.modelID, 'lda')
                        child = initFcn(mdlObj.Parent, mdlObj.Origin, mdlObj.dfID_source, mdlObj.predictorID);
                    else
                        child = initFcn(mdlObj.Parent, mdlObj.Origin, mdlObj.dfID_source);
                    end
                    child.domain      = mdlObj.domain;
                    child.pMap        = mdlObj.pMap;
                    child.cfg         = mdlObj.cfg;
                    child.collector   = mdlObj.collector;   % child construction
                        % (initTargetBus()/setupDomain() in the subclass
                        % constructor) rebuilds collector.Target/Domain/
                        % Pointer from defaults -- without this, any Target/
                        % nBins the user explicitly set on the PARENT's own
                        % Figure (e.g. mdlObj_lme's Target dropdown, read by
                        % nexFit_lme.m off the CHILD's collector) is silently
                        % discarded, reverting to whatever a fresh
                        % initTargetBus() call defaults to.
                    child.fitSentinel = mdlObj.fitSentinel;   % children never
                        % call their own compileSTAT() (STAT is sliced directly
                        % from the already-canonicalized parent STAT below), so
                        % the canonical REG set has to come from the one
                        % alignment pass that already ran at the top level —
                        % inherited verbatim, not recomputed per combo.
                    child.STAT      = mdlObj.STAT(mask, :);
                    child.trainMask = true(height(child.STAT), 1);
                    child.getDesignMatrix();
                    child.cfg.fitCfg.fcn(child, child.cfg.fitCfg.entryParams);
                    child.DM = [];
                    fprintf('[mdlObject] fitByCombo: combo %d/%d (%d trial(s)) fit\n', ...
                            ci, nCombos, height(child.STAT));
                    newComboFits(end+1) = struct('key', key, 'child', child); %#ok<AGROW>
            end
            mdlObj.comboFits = newComboFits;
            mdlObj.DM = [];
        end

        function partialFit(mdlObj, X, Y)
             % Convert MATLAB 3D or 2D data into proper NumPy ndarrays
            np = py.importlib.import_module('numpy');
        
            % Ensure doubles
            X = double(X);
            Y = double(Y);
        
            % Convert to contiguous NumPy arrays
            X_py = np.ascontiguousarray(np.array(X));
            Y_py = np.ascontiguousarray(np.array(Y));
        
            % Call partial_fit
            mlObj.model.partial_fit(X_py, Y_py);        
            
        end

        function Z = transform(mdlObj, X)
            np = py.importlib.import_module('numpy');
            X_py = np.ascontiguousarray(np.array(double(X)));            
            Z_py = mdlObj.model.transform(X_py);
            Z = double(np.array(Z_py));
        end

        function DF_Z = transformInput(mdlObj, DF_X)
            % recurse through mdlObj preceding layers to invoke
            % transformation sequence (up to primary caller's level; if called at predictor level, 
            % full sequence should be traversed)
            Parent = mdlObj.Parent;
            parentClass = class(Parent);
            if strcmp(parentClass,"nexObj_categorical") % BASE: if parent is categorical
                DF_Z = mdlObj.transform(DF_X);
            elseif contains(parentClass,"mdlObj") % RECURSE: if parent is a model
                DF_Z_pre = Parent.transformInput(DF_X);
                DF_Z = mdlObj.transform(DF_Z_pre);
            end  
        end

        function scaleApply_transform(mdlObj, dfID_source, isOverwrite, currentTrialOnly, outputLabel)

            % CFG HEADER
            scope = "local"; % scope : global/local

            % apply fit transform row-by-row — avoids loading entire column into memory
            if nargin < 2 || isempty(dfID_source),   dfID_source    = mdlObj.dfID_source; end
            if nargin < 3 || isempty(isOverwrite),   isOverwrite    = true;  end
            if nargin < 4 || isempty(currentTrialOnly), currentTrialOnly = false; end
            % outputLabel: optional caller-supplied full override for this
            % transform's output patch ID (not a suffix — replaces
            % mdlObj.dfID_target entirely for this call, so distinct
            % labels never collide with each other or the default).
            % Affects ONLY the output artifact name computed below — never
            % mdlObj.dfID_target itself, which keeps whatever it already
            % means (an output artifact ID for transform models, but the
            % STAT column name for the prediction label on Predictor
            % models like lda/logistic — mutating it here would silently
            % break those models' next fit/predict call).
            if nargin < 5 || isempty(outputLabel), outputLabel = ""; end
            mdlObj.lastOutputLabel = string(outputLabel);
            dfID_entry = strrep(dfID_source, "_df", "");
            dnSel = mdlObj.domain.DN(1);
            % dtsRows = height(mdlObj.nexon.console.BASE.DTS);
            switch scope
                case "global"
                    % mask global selection
                    S = nex_returnSelectionMask(mdlObj.nexon.console.BASE.controlPanel.averagingSelection);
                    idxSel = nex_applySelectionMask(mdlObj.nexon.console.BASE.DTS, S);                                                    
                case "local"
                    % mask sub selection (only transform samples trained on)                    
                    S_items = nex_returnSelectionMask(mdlObj.Origin.selectionBus.items);                    
                    S_categories = nex_returnSelectionMask(mdlObj.Origin.selectionBus.categories);
                    ctgFields = convertCharsToStrings(fieldnames(S_categories));
                    for i = 1:length(ctgFields); S_categories.(ctgFields(i)) = split(S_categories.(ctgFields(i)),"--"); end                    
                    ctgKeys = structfun(@(s) s(end), S_categories);
                    for i = 1:length(ctgFields); S_categories.(ctgFields(i)) = ctgKeys(i); end                    
                    S_merge = outerjoinStructs(S_categories, S_items);
                    idxSel = nex_applySelectionMask(mdlObj.nexon.console.BASE.DTS, S_merge);                    
            end
            if currentTrialOnly
                ridx = nex_getRouterIdx(mdlObj.nexon);
                if islogical(ridx), ridx = find(ridx); end
                rowIdxs = ridx(1:min(1, end));
            else
                rowIdxs = find(idxSel==1);
            end

            % Output routing. The transform output always lands on dfID_target —
            % never back on the source. For a disk-backed DTS it is written to a
            % Output routing — mirrors nexTract's convention:
            %   disk-backed row  → dedicated sibling patch HDF5, manifest registered
            %   in-memory row    → dtsIO_writeDF with forceMem (hybrid DTS support)
            %   pure in-memory   → dtsIO_writeDF, patchManifest pending mode
            nexon        = mdlObj.nexon;
            dfID_out     = char(mdlObj.dfID_target);
            if strlength(outputLabel) > 0
                dfID_out = char(outputLabel);   % full override, not a suffix — the field is the whole patch ID
            end
            isDiskBacked = ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames);
            h5FileOut    = '';

            if isDiskBacked
                % Use the first row with a non-empty h5_path (row 1 may be
                % in-memory in a hybrid DTS, which would give a bad path).
                allH5     = string(nexon.console.BASE.DTS.h5_path);
                firstDisk = find(strlength(allH5) > 0, 1);
                if ~isempty(firstDisk)
                    [pd, pb, pe] = fileparts(char(allH5(firstDisk)));
                    h5FileOut = fullfile(pd, [pb '_' dfID_out pe]);
                end
                dtsIO_patchManifest(nexon, dfID_out, h5FileOut);
            else
                % Pure in-memory DTS: register pending so Sink creates the patch.
                dtsIO_patchManifest(nexon, dfID_out, []);
            end

            for r = 1:length(rowIdxs)
                i = rowIdxs(r);
                fprintf("row: %d \n", i);
                disp(nexon.console.BASE.DTS.sessionLabel{i});
                DF_X = dtsIO_readDF(nexon, dfID_entry, i);
                if isempty(DF_X) || ~isfield(DF_X, 'df') || isempty(DF_X.df)
                    continue
                end
                DF_X.ptr = nexInit_axisPointer(DF_X.df, DF_X.ax);
                % Combo dispatch — pick the child mdlObj that fitByCombo
                % independently fit for this trial's CTG combination, by
                % matching this DTS row against each child's stored key
                % (nexOp_matchComboRow — same matcher fitByCombo used to
                % slice STAT by combo at fit time). Empty comboFits means
                % "single model" mode, unchanged from before this feature.
                % A trial matching none of the fitted combos is skipped
                % outright — it doesn't belong to any category combination
                % the model was trained on, so transforming it is
                % meaningless to first order (deferred: a systematic
                % "test"/held-out-combo case, per user).
                if isempty(mdlObj.comboFits)
                    activeChild = mdlObj;
                else
                    activeChild = [];
                    dtsRow = nexon.console.BASE.DTS(i, :);
                    for ck = 1:numel(mdlObj.comboFits)
                        if nexOp_matchComboRow(dtsRow, mdlObj.comboFits(ck).key)
                            activeChild = mdlObj.comboFits(ck).child;
                            break;
                        end
                    end
                    if isempty(activeChild)
                        fprintf("row %d matches no fitted CTG combo — skipping (not transformed).\n", i);
                        continue
                    end
                end
                % Project onto the SAME canonical REG positions the model
                % was fit on (CoRegistration_Design.md, "Inference-Time
                % Projection") — before Pointer/pooling, same align-before-
                % pool reasoning as nexOp_compileSTAT: positional pooling
                % computes bins from each trial's own raw extent, so this
                % must canonicalize first or it'd align already-scrambled
                % session-relative labels instead of true cross-session
                % identity. Uses activeChild's own fitSentinel — in combo
                % mode each child skips its own compileSTAT (see
                % fitByCombo), so mdlObj's fitSentinel is never populated;
                % activeChild.fitSentinel is either the same object's own
                % (single-model mode) or the inherited-at-fit-time copy
                % (combo mode; see fitByCombo).
                if isstruct(activeChild.fitSentinel) && isfield(activeChild.fitSentinel, 'canonReg') ...
                        && isfield(DF_X.ax, activeChild.fitSentinel.regAxis)
                    canonReg_i = activeChild.fitSentinel.canonReg;
                    % bySubject fitSentinel (compileSTAT canonicalized per-
                    % subject because its TF spanned more than one subject) —
                    % canonReg_i is a containers.Map keyed by subject id;
                    % look up THIS trial's own subject rather than assuming
                    % one flat canonical set applies to every trial. Missing
                    % the isfield guard would break on an older, already-
                    % persisted fitSentinel (e.g. a reloaded PCA fit) that
                    % predates this field.
                    if isfield(activeChild.fitSentinel, 'bySubject') && activeChild.fitSentinel.bySubject
                        subjKey = char(parseSessionLabel(string(nexon.console.BASE.DTS.sessionLabel{i}), "subj"));
                        if isKey(canonReg_i, subjKey)
                            canonReg_i = canonReg_i(subjKey);
                        else
                            canonReg_i = [];   % subject never seen at fit time — skip projection
                        end
                    end
                    if ~isempty(canonReg_i)
                        TF1  = nexOp_alignCoAxes({DF_X}, activeChild.fitSentinel.regAxis, [], ...
                                                  canonReg_i);
                        DF_X = TF1{1};
                        DF_X.ptr = nexInit_axisPointer(DF_X.df, DF_X.ax);
                    end
                end
                % Pool BEFORE Pointer-filtering — matches the fit-side order
                % in nexOp_compileSTAT (align -> pool -> ... -> applyPointer
                % back in mdlObject.compileSTAT()). Region-mode pooling
                % (pMap divsPerBin=0, binType='region') relabels chans/unit
                % from raw IDs to region NAMES without changing width — the
                % Pointer bus's "select STN" only ever matches against
                % those region labels, which don't exist until pooling has
                % run. Filtering first (the old order here) matched a
                % region-name selection against still-raw channel/unit IDs,
                % silently matched nothing, and passed every position
                % through unfiltered.
                if ~isempty(mdlObj.pMap)
                    DF_X = nexOp_poolAxes(mdlObj.pMap, DF_X, DF_X.ptr);
                    DF_X.ptr = nexInit_axisPointer(DF_X.df, DF_X.ax);
                end
                if isfield(mdlObj.collector, 'Pointer') && ~isempty(mdlObj.collector.Pointer)
                    DF_X = mdlObj.applyPointerDF(DF_X);
                end
                DF_X = mdlObj.applyDomainMSRDF(DF_X);
                if dnSel ~= "None"
                    DF_X = nexOp_permute2First(DF_X, dnSel, DF_X.ptr);
                end
                try
                    DF_Z = activeChild.transform(DF_X);
                catch e
                    disp(getReport(e)); continue
                end
                if isempty(DF_Z) || isempty(DF_Z.df), continue; end

                if isDiskBacked
                    h5Root = char(nexon.console.BASE.DTS.h5_root(i));
                    if isempty(h5Root)
                        % Hybrid in-memory row — write to in-memory DTS.
                        dtsIO_writeDF(nexon, DF_Z, dfID_out, i, true);
                    else
                        % Disk-backed row.
                        groupPath = [h5Root '/' dfID_out];
                        if ~isOverwrite
                            try, h5info(h5FileOut, groupPath);
                                fprintf("skipping row %d (already written)\n", i); continue
                            catch, end
                        end
                        mdlObj_h5ClearGroup(h5FileOut, groupPath);
                        fprintf("patching %s -> %s\n", dfID_out, h5FileOut);
                        dtsIO_writeDF_toHDF5(h5FileOut, h5Root, dfID_out, DF_Z);
                    end
                else
                    dtsIO_writeDF(nexon, DF_Z, dfID_out, i);
                end
            end
        end

        function [STAT, idxSel, drop] = compileSTAT(mdlObj)
            % use categorical parent selection to compile dfID_source relative STAT
            % table
            Parent = mdlObj.Parent;
            parentClass = class(Parent);
            if strcmp(parentClass,"nexObj_categorical") % if parent is categorical
                S_categories = nex_returnSelectionMask(Parent.selectionBus.categories);
                S_items = nex_returnSelectionMask(Parent.selectionBus.items);
                % Reuses precompileSTAT()'s cached alignment when present —
                % nexOp_compileSTAT then skips straight past re-alignment
                % (and the refreshPointerFromPool side effect that would
                % otherwise wipe whatever Pointer subselection was made
                % since Compile was pressed). Empty by default, so this is
                % a no-op for anyone who never calls precompileSTAT.
                [STAT, idxSel, drop] = nexOp_compileSTAT(mdlObj, mdlObj.dfID_source, S_categories, S_items, [], mdlObj.precompiledAligned, mdlObj.resolveWithinSubject_());
                % STAT = nexOp_compileSTAT(Parent, mdlObj.dfID_source, S_categories, S_items, []);
            elseif contains(parentClass,"mdlObj") % if parent is a model
                STAT = Parent.transformSTAT(Parent.STAT);
            end
            % STAT.df = nexOp_trimDfCol(STAT.df);
            %% STAT conditioning/standardizing
            % if mdlObj.cfg.statCfg.entryParams.fuseAx
            %     % statVars = STAT.Properties.VariableNames;
            %     % groupIDCols = convertCharsToStrings(statVars(contains(statVars,"ax_")));
            %     STAT = nexOp_fuseGroups(STAT, "trialNumber");
            % end
            TF_STAT=arrayfun(@(s) {s}, (table2struct(STAT)));
            % Resolve regAxis/ftrAxis (now lists, not single names) so
            % nexOp_trimTF leaves EVERY such axis alone instead of forcing
            % every row to one shared width/representative row. Checked
            % FIRST against mdlObj.pMap directly: ANY axis configured for
            % mapID/lookup-type pooling (the same "isMapID" test
            % nexOp_poolAx.m/nexObj_poolMap.m already use internally) —
            % not just one — genuinely produces per-subject-varying values
            % (e.g. 'chans'->region names AND 'f'->band names can BOTH be
            % mapID-pooled on the same mdlObj simultaneously) — so EACH of
            % their per-row identities must survive this trim/broadcast,
            % regardless of domain.REG. domain.REG is a SEPARATE concept
            % (cross-sample identity registration tied to the FEATURE
            % axis — its own UI options are restricted to FTR's
            % co-indexed partners, so e.g. an FTR="f" LDA can never set
            % REG="chans" even when pMap.chans is doing real region-mode
            % pooling that still needs this restore) — falls back to the
            % original domain.REG/fitSentinel mechanism only when pMap
            % reveals no mapID-pooled axis at all, preserving existing
            % behavior for every other caller.
            regAxis = {}; ftrAxis = {};
            try
                pmFields = fieldnames(mdlObj.pMap);
                for pfi = 1:numel(pmFields)
                    pmf = mdlObj.pMap.(pmFields{pfi});
                    if ~(isprop(pmf, 'binType') && isprop(pmf, 'mapID') && ...
                            ~isempty(pmf.mapID) && string(pmf.binType) == string(pmf.mapID))
                        continue;
                    end
                    ra = char(pmf.axSel);
                    fa = '';
                    if ismember(ra, fieldnames(STAT.ptr(1))) && ~isempty(STAT.ptr(1).(ra).dim)
                        fa = ra;
                    else
                        coIdx     = nexOp_coIndexPairs(STAT.ax(1));
                        ptrFields = fieldnames(STAT.ptr(1));
                        for p = 1:numel(coIdx)
                            pair = coIdx{p};
                            if ~ismember(ra, pair), continue; end
                            for mIdx = 1:numel(pair)
                                cand = char(pair{mIdx});
                                if strcmp(cand, ra) || ~ismember(cand, ptrFields), continue; end
                                if ~isempty(STAT.ptr(1).(cand).dim)
                                    fa = cand;
                                    break;
                                end
                            end
                            if ~isempty(fa), break; end
                        end
                    end
                    if ~isempty(fa)
                        regAxis{end+1} = ra; %#ok<AGROW>
                        ftrAxis{end+1} = fa; %#ok<AGROW>
                    end
                end
                if isempty(regAxis) && ismember('domain', fieldnames(mdlObj)) && isfield(mdlObj.domain, 'REG') ...
                        && ~strcmp(char(mdlObj.domain.REG), 'None') ...
                        && isstruct(mdlObj.fitSentinel) && isfield(mdlObj.fitSentinel, 'ftrAxis')
                    regAxis = {char(mdlObj.domain.REG)};
                    ftrAxis = {char(mdlObj.fitSentinel.ftrAxis)};
                end
            catch e
                fprintf('[mdlObject.compileSTAT] regAxis/ftrAxis resolution skipped: %s\n', e.message);
                regAxis = {}; ftrAxis = {};
            end
            [df_trim,ax_trim]=nexOp_trimTF(TF_STAT, regAxis, ftrAxis);
            dnSel=mdlObj.domain.DN(1);
            STAT.df=df_trim;
            STAT.ax=arrayfun(@(ax) ax_trim, STAT.ax);
            % ax_trim above is only ONE representative row's REG/FTR
            % identity, broadcast to every row — correct for every OTHER
            % axis (all rows already share those), but wrong for REG/FTR
            % whenever STAT spans subjects with different per-subject
            % canonical sets (nexOp_trimTF left each row's own REG/FTR
            % untouched above specifically so this restore has real
            % per-row data to pull from, instead of silently mislabeling
            % every row with row 1's subject's channel/unit identities).
            for ri = 1:height(STAT)
                for ai = 1:numel(regAxis)
                    STAT.ax(ri).(regAxis{ai}) = TF_STAT{ri}.ax.(regAxis{ai});
                end
                for ai = 1:numel(ftrAxis)
                    if ~isempty(ftrAxis{ai}) && isfield(TF_STAT{ri}.ax, ftrAxis{ai})
                        STAT.ax(ri).(ftrAxis{ai}) = TF_STAT{ri}.ax.(ftrAxis{ai});
                    end
                end
            end
            ptr = STAT.ptr(1);
            % place primary dim first (skip when DN="None" — trial is the sample)
            if dnSel ~= "None"
                STAT.df = cellfun(@(df) nexOp_permute2First(df, dnSel, ptr), STAT.df, "UniformOutput", false);
            end
            % broadcast new pointer after permute
            DF_ptr = table2struct(STAT(1,:)); DF_ptr = rmfield(DF_ptr,"ptr");
            DF_ptr =nex_initAxisPointer_v2(DF_ptr);
            STAT.ptr = repmat(DF_ptr.ptr,height(STAT),1);

            % Apply Pointer window if user has made an axis selection. The
            % bus is already correct by this point — refreshPointerFromPool
            % ran once, upstream, inside nexOp_compileSTAT right after the
            % last FRESH alignment (Compile press, or a cold Fit) — so no
            % refresh call belongs here; doing it on every compileSTAT()
            % call (including cache-reusing ones) is what caused Pointer
            % selections to get silently wiped on repeated Fits.
            if isfield(mdlObj.collector, 'Pointer') && ~isempty(mdlObj.collector.Pointer)
                STAT = mdlObj.applyPointer(STAT);
            end

            % Collapse the residual (MSR) axis per the Domain bus selection
            STAT = mdlObj.applyDomainMSR(STAT);

            mdlObj.STAT=STAT;
        end

        function precompileSTAT(mdlObj)
        % Run compile+align (establishes fitSentinel and seeds the Pointer
        % bus's options — every pMap-pooled axis, not just REG — to the
        % true canonical set, via nexOp_compileSTAT's own
        % refreshPointerFromPool side effect) WITHOUT yet applying pooling
        % or building the final STAT table (pooling itself is cheap and
        % re-derived fresh on every compileSTAT() call regardless — see
        % refreshPointerFromPool). Caches the alignment so compileSTAT()
        % (called by fit()) reuses it — skipping re-alignment/re-refresh —
        % meaning a Pointer/pMap subselection (e.g. groupBy='region', pick
        % specific regions) made AFTER pressing this survives untouched
        % into Fit, rather than being silently reset by a second
        % refreshPointerFromPool call. Stays cached across repeated Fits
        % until invalidatePrecompile() clears it (categorical selection
        % change, REG change, or pressing this again).
            mdlObj.ensurePrecompileWatchers_();
            Parent = mdlObj.Parent;
            if ~strcmp(class(Parent), "nexObj_categorical")
                warning('[mdlObject] precompileSTAT: Parent is not nexObj_categorical — nothing to precompile.');
                return;
            end
            S_categories = nex_returnSelectionMask(Parent.selectionBus.categories);
            S_items      = nex_returnSelectionMask(Parent.selectionBus.items);
            [~, ~, ~, aligned] = nexOp_compileSTAT(mdlObj, mdlObj.dfID_source, S_categories, S_items, [], [], mdlObj.resolveWithinSubject_());
            mdlObj.precompiledAligned = aligned;
            fprintf(['[mdlObject] precompiled STAT ready (%d trial(s)) — Pointer bus ' ...
                     'options now reflect the full canonical set; adjust your selection, ' ...
                     'then Fit.\n'], numel(aligned.TF));
        end

        function STAT = buildSTATFromPrecompiled(mdlObj)
        % Rebuild STAT straight from the cached mdlObj.precompiledAligned
        % (the already-aligned/canonicalized per-trial TF from the last
        % precompileSTAT()/Compile press) -- a thin, explicitly-named
        % entry point for the SAME reuse path mdlObj.compileSTAT() already
        % takes internally whenever precompiledAligned is non-empty (see
        % nexOp_compileSTAT's own `if isempty(precompiled)` gate, which
        % skips straight past the expensive raw-DTS-read +
        % nexOp_alignCoAxes/nexOp_poolAxes realignment step and goes
        % directly to category-label attachment + per-trial breakout +
        % table assembly) -- the same mechanism nexAnalysis_cvPermute
        % relies on in-process for its own per-fold STAT rebuilds, exposed
        % here as its own directly-callable method rather than only as an
        % internal fast path. Deliberately does NOT re-implement any of
        % compileSTAT()'s own post-processing (trimTF, etc.) -- calls
        % compileSTAT() itself so there is exactly one code path to keep
        % correct, not two that could drift apart.
        %
        % Useful whenever you want a fresh STAT re-derived straight from
        % the cached alignment without repeating the (often genuinely
        % expensive) raw-DTS-read/align/pool step — e.g. after discovering
        % mdlObj.STAT itself was mutated in place by something else
        % (applyPointer, ...) and you want to rebuild a clean copy from
        % the same underlying trials, not recompile from scratch.
            if isempty(mdlObj.precompiledAligned) || isempty(mdlObj.precompiledAligned.TF)
                error('mdlObject:buildSTATFromPrecompiled:empty', ...
                    ['mdlObj.precompiledAligned is empty -- call precompileSTAT() ' ...
                     '(or press Compile) at least once first.']);
            end
            STAT = mdlObj.compileSTAT();
            mdlObj.STAT = STAT;
            fprintf(['[mdlObject.buildSTATFromPrecompiled] rebuilt STAT (%d row(s)) from ' ...
                     'cached precompiledAligned (%d trial(s)).\n'], ...
                height(STAT), numel(mdlObj.precompiledAligned.TF));
        end

        function invalidatePrecompile(mdlObj)
        % Drops the precompileSTAT() cache — called whenever something
        % that would change canonicalization/TF-compilation changes: the
        % Origin categorical's own category/item selection (via the
        % PostSet listeners ensurePrecompileWatchers_ wires), or
        % domain.REG (via applyDomainBus/refreshREG). Setting the property
        % to [] drops the only reference to the cached TF (a cell array of
        % full per-trial DFs), freeing it for garbage collection rather
        % than just flagging it stale while the memory stays held. fit()'s
        % next compileSTAT() call falls back to a full recompile, same as
        % if precompileSTAT() had never been called.
            if isempty(mdlObj.precompiledAligned), return; end
            mdlObj.precompiledAligned = [];
            fprintf(['[mdlObject] precompiled STAT invalidated (categorical selection or ' ...
                     'REG changed) — Fit will recompile from scratch, or press Compile ' ...
                     'again first.\n']);
        end

        function tf = resolveWithinSubject_(mdlObj)
        % Gate nexOp_compileSTAT's REG canonicalization scope on whether
        % subject is itself one of THIS fit's CTG stratification columns —
        % mirrors nexObject.reportAverage's identical gate (same reasoning:
        % subject-in-CTG means every downstream slice is subject-pure, so
        % per-subject canonicalization keeps each subject's own REG
        % identity correct; subject-not-in-CTG means trials are meant to
        % share one pooled feature space across subjects, so a single
        % global canonicalization pass is what keeps that space consistent
        % — nexOp_compileSTAT's own positional steps downstream (e.g.
        % nexOp_trimTF at the end of compileSTAT here) are only ever safe
        % when every DF feeding them already shares one canonical layout,
        % which one or the other of these guarantees).
            try
                tf = ismember("sessionLabel_subj", string(mdlObj.domain.CTG));
            catch
                tf = true;   % default to the safer (per-subject) scope
            end
        end

        function ensurePrecompileWatchers_(mdlObj)
        % Lazily wires the two PostSet listeners invalidatePrecompile()
        % needs — on the Origin categorical's own categories/items
        % selectionBus 'selections' property (SetObservable on
        % nexObj_selectionBus). Runs once per mdlObj instance, on first
        % precompileSTAT() call, so subclasses that never precompile never
        % pay for listeners they don't need.
            if mdlObj.precompileWatchersWired, return; end
            mdlObj.precompileWatchersWired = true;
            try
                mdlObj.precompileListeners.categories = addlistener( ...
                    mdlObj.Origin.selectionBus.categories, 'selections', 'PostSet', ...
                    @(~,~) mdlObj.invalidatePrecompile());
                mdlObj.precompileListeners.items = addlistener( ...
                    mdlObj.Origin.selectionBus.items, 'selections', 'PostSet', ...
                    @(~,~) mdlObj.invalidatePrecompile());
            catch
                % Origin/selectionBus unavailable (e.g. headless
                % reconstruction with no live categorical parent) — the
                % cache just won't auto-invalidate from categorical
                % changes; REG changes and manual re-Compile still work.
            end
        end

        function STAT_tf = transformSTAT(mdlObj, STAT_in)
            % apply transform to all rows in STAT
            % overwrite df, ax, ptr cols
            % STAT_tf = mdlObj.transform(STAT_in);
            % TF_X = stat2TF(STAT_in);
            TF_X = table2struct(STAT_in);
            TF_Z = arrayfun(@(DF) mdlObj.transform(DF), TF_X, "UniformOutput", false);
            TF_Z_cat = cat(1, TF_Z{:});
            STAT_tf=struct2table(TF_Z_cat);
            % STAT_tf = STAT_in.transform();
        end

        function cvPermute(mdlObj)
           
            args = mdlObj.cfg.cvCfg.entryParams;

            % CFG HEADER
            nFolds = args.nFolds; % default = 5
            nPermute = args.nPermute; % default = 50

            nexAnalysis_cvPermute(mdlObj);
            
        end

        function crossValidate(mdlObj)
            
            args = mdlObj.cfg.cvCfg.entryParams;

            % CFG HEADER
            numFolds = args.numFolds; % default = 10            
            isShuffle = args.isShuffle; % default = 0

            % for each fold:
            % generate a model            
            initFcn = str2func(sprintf("mdlObj_%s",mdlObj.modelID));
            mdlIDs_cv = cellstr(compose("M%d",1:numFolds))';                        
            S_cv = cell2struct(cell(size(mdlIDs_cv)), mdlIDs_cv);
            mdlObjs = structfun(@(s) initFcn(mdlObj.Parent, mdlObj.Origin, mdlObj.dfID_source, mdlObj.predictorID), S_cv);
            mdlObjs = arrayfun(@(m) {m}, mdlObjs);                        
            mdlObj.CV = cell2struct(mdlObjs, mdlIDs_cv);      
            % prepare folds
            stratVar = mdlObj.STAT.(mdlObj.dfID_target);
            trainMasks= nexStat_allocateFolds(stratVar, numFolds);

            TEST_PRED=[];
            for i = 1:length(mdlIDs_cv)
                mdlID = mdlIDs_cv{i};
                mdlObj_cv = mdlObj.CV.(mdlID);
                % mdlObj_cv.STAT = mdlObj.STAT;
                mdlObj_cv.trainMask = trainMasks{i};
                % train the model (on a subpartition) 
                mdlObj_cv.fit();
                % save the test data (TEST.data)
                % if model IS predictor
                    % predict (TEST.predictions)
                % if model HAS predictor
                    % generate outputs and train predictor
                % predict
                TEST_pred = mdlObj_cv.predictTEST();
                TEST_PRED = [TEST_PRED; TEST_pred];
                % mdlObj_cv.predictor.predict();
               
            end
            mdlObj.TEST.STAT=TEST_PRED;            
            % score (TEST.CM 'confusion matrix')        
            mdlObj.reportTestAverage();            
            for i = 1:numFolds
                mdlObj_cv=mdlObjs{i};
                % mdlObj_cv.reportTestAverage();
                mdlObj_cv.model.get_params;
                double(mdlObj_cv.model.coef_);
            end
            Y_true=mdlObj.TEST.STAT.(mdlObj.dfID_target);
            TF_preds = mdlObj.TEST.STAT.prediction;
            % [TF_probs, TF_scores] = cellfun(@(DF) max(mean(DF.df,1)), TF_preds, "UniformOutput",false);
            [TF_probs] = cellfun(@(DF) (mean(DF.df,1)), TF_preds, "UniformOutput",false);
            TF_probs=cat(1,TF_probs{:});
            L=TF_preds{1}.ax.(mdlObj.dfID_target);
            Scores = cellfun(@(score) L(score), TF_scores);            
            rocObj = rocmetrics(nexOp_labelEncode(Y_true), TF_probs, [1:4], NumBootstraps=1000);
            % rocObj = rocmetrics(nexOp_labelEncode(Y_true), nexOp_labelEncode(Scores),NumBootstraps=1000);
            % % accuracy = [];
            % % AUC = auc(rocObj);

            % aggregate and plot results (model.Figure - using the primary model)
           

        end

        function STAT_pred = predictTEST(mdlObj)
                % if isequal(mdlObj_cv, mdlObj_cv.predictor)
                STAT_test = mdlObj.TEST.STAT;
                TF_X = table2struct(STAT_test);
                TF_pred = arrayfun(@(DF) mdlObj.predict(DF), TF_X,"UniformOutput",false);
                STAT_pred=STAT_test;
                STAT_pred.prediction=TF_pred;
                mdlObj.TEST.STAT=STAT_pred;
                % STAT_pred = [];                    
                % else                    
                % 
                %     STAT_test = mdlObj_cv.TEST.STAT;
                %     TF_pred = cellfun(@(DF) mdlObj_cv.model.predictor.predict(DF), TF_X);
                % 
                %     mdlObj_cv.predictor.predict();
                %     mdlObj.TEST.predictions = [];
                % end
        end

        function reportTestScores(mdlObj)
            %  evaluate prediction accuracy and visualize results
        end

        function AVG = reportTestAverage(mdlObj)
            % gather average predictions within groups and visualize
            % results
            % stat. averaging on test-predictions, split into target groups
            % with 'AVG' table formatting
            %% GATHER
            STAT_test = mdlObj.TEST.STAT;
            G = STAT_test.(mdlObj.dfID_target); % get target groupings
            G_enum = findgroups(G);
            predictions = STAT_test.prediction;
            AVG = splitapply(@(TF) nexOp_averageTF(TF), predictions, G_enum);
            avgCfg = nexTract_avgCfg(mdlObj.nexon);
            % mgph store-conditioning (temporary{)
            avgCfg = rmfield(avgCfg,"phase");
            avgCfg = rmfield(avgCfg,"date");            
            labels_G = strrep(unique(G),"-","_");
            avgs_G = arrayfun(@(DF) {DF}, AVG); % parcelate
            for i = 1:size(AVG,1); avgs_G{i}.avgCfg=avgCfg; end
            AVG = cell2struct(avgs_G, cellstr(labels_G));
            
            %% VISUALIZE
            % empty monograph (visualize)
            mdlObj.Partners.mgph1 = nexObj_monoGraph([],mdlObj,mdlObj.nexon,[],[], AVG.(labels_G(1)));
            mdlObj.Partners.mgph1.UserData.T_avg=table({AVG}, avgCfg, 'VariableNames',{'AVG','avgCfg'});
            mdlObj.Partners.mgph1.visualize();
            % structfun(@(s) nex_storeAverage(mdlObj.Partners.mgph1, s), AVG);

        end

        function updateScope(mdlObj) %#ok<MANU>
            % No-op for mdlObject. Called by nexObj_poolCfgPanel Apply button;
            % pool config is already stored in pMap via callbacks — refit is
            % user-triggered via the Fit button.
        end

        function W = getFeatureWeights(mdlObj)
        % Generic linear-model weight extraction — works unmodified across
        % lda/logistic/linear/ridge/lasso (verified: model_lda.m,
        % model_logistic.m, model_linear.m all build sklearn linear-model-
        % family objects, which uniformly expose .coef_/.intercept_ — this
        % is sklearn's own deliberate cross-estimator API contract, not a
        % coincidence). Same isprop(model,'coef_') idiom nexFit_linear.m
        % already uses for its own sparsity report.
        %
        % Returns plain doubles in sklearn's own native shape — caller's
        % job to reshape/interpret (e.g. nexAnalysis_cvPermute assembling
        % a [nFeatures x nFolds x (1+nPermute) x nSwp...] array from many
        % calls to this). Both fields empty if the fitted model doesn't
        % expose these (not yet fit, or a future non-linear model type —
        % see the "other faculties" discussion: nonlinear decoders need a
        % genuinely different extractor, not a smarter version of this
        % one — this method deliberately stays linear-only and honest
        % about that rather than faking a universal abstraction).
            W = struct('coef', [], 'intercept', []);
            try
                if isprop(mdlObj.model, 'coef_')
                    W.coef = double(py.numpy.array(mdlObj.model.coef_));
                end
                if isprop(mdlObj.model, 'intercept_')
                    W.intercept = double(py.numpy.array(mdlObj.model.intercept_));
                end
            catch ME
                % Surfaced rather than silently swallowed — a caller
                % consolidating many calls to this (nexAnalysis_cvPermute)
                % has no other way to tell "genuinely non-linear model" apart
                % from "this particular fit's coef_ extraction actually
                % failed", and the latter was invisible before this warning.
                warning('[mdlObject.getFeatureWeights] coef_/intercept_ extraction failed: %s', ME.message);
            end
        end

        function saveFit(mdlObj, uniqueID)
            % Subclasses override. Creates a folder named mdlObj_{modelID}_{uniqueID}
            % and serializes all fit artifacts into it. Python objects must go
            % through Python (pickle / npz) — MATLAB save() cannot handle them.
        end

        function loadFit(mdlObj, fitDir)
            % Subclasses override. Restores fit artifacts from the folder
            % produced by saveFit.
        end

        function h5File = saveRESULT(mdlObj, resultID)
        % Persist mdlObj.RESULTS.(resultID) to nexRESULTS.h5 alongside the
        % DTS — same file/layout nexObject's own RESULTS use
        % (nexOp_saveResult/nexOp_loadResult), extended to also carry the
        % weights facet (W/ax_W/featureLabels — Nexus WIP.md #11) a
        % cvPermute RESULTS row can have and a plain nexObject row never
        % does. fitSentinel is NOT persisted (canonReg can be a
        % containers.Map — fit-time projection state, not analysis
        % output); ptr/ptr_W are never stored either, both reconstructed
        % on load from df/ax and W/ax_W respectively.
            h5File = nexOp_saveResult(mdlObj, resultID);
        end

        function T = loadRESULT(mdlObj, resultID)
        % Load a previously saveRESULT-saved entry back into
        % mdlObj.RESULTS.(resultID) and return it. Does not touch
        % mdlObj.STAT/DM/fit state — this restores an analysis OUTPUT,
        % not a trained model (use loadFit for that).
            T = nexOp_loadResult(mdlObj, resultID);
            mdlObj.RESULTS.(char(resultID)) = T;
        end

        function saveFitAll(mdlObj, uniqueID)
        % Combo-aware save. comboFits empty (single-model mode, today's
        % default) — just mdlObj.saveFit(uniqueID), unchanged, dispatching
        % to whatever the subclass overrides.
        %
        % comboFits populated — delegates to each child's OWN saveFit (the
        % same subclass override, since every child is constructed via
        % initFcn = str2func(class(mdlObj)) in fitByCombo), passing
        % fullfile(uniqueID, 'combo_<k>') as that child's uniqueID. Every
        % subclass's saveFit already builds its fitDir as
        % fullfile(root, sprintf('mdlObj_<modelID>_%s', uniqueID)), so
        % nesting the combo subfolder into uniqueID this way produces one
        % shared parent folder (mdlObj_<modelID>_<uniqueID>) containing a
        % combo_<k> subfolder per child — with zero subclass changes. A
        % comboManifest.mat next to the parent folder records each combo's
        % key + subfolder, so loadFitAll can restore everything given only
        % mdlObj.fitPath.
            if isempty(mdlObj.comboFits)
                mdlObj.saveFit(uniqueID);
                return;
            end
            manifest = struct('key', {}, 'folder', {});
            topDir   = '';
            for k = 1:numel(mdlObj.comboFits)
                folder = sprintf('combo_%d', k);
                child  = mdlObj.comboFits(k).child;
                child.saveFit(fullfile(uniqueID, folder));
                if isempty(topDir)
                    topDir = fileparts(child.fitPath);   % shared mdlObj_<modelID>_<uniqueID> dir
                end
                manifest(k).key    = mdlObj.comboFits(k).key;
                manifest(k).folder = folder;
            end
            save(fullfile(topDir, 'comboManifest.mat'), 'manifest');
            mdlObj.fitPath = topDir;
            fprintf('[mdlObject] saveFitAll: %d combo fit(s) saved under %s\n', ...
                    numel(mdlObj.comboFits), topDir);
        end

        function loadFitAll(mdlObj, fitDir)
        % Combo-aware load, counterpart to saveFitAll. comboFits empty —
        % just mdlObj.loadFit(fitDir), unchanged. comboFits populated —
        % mdlObj.comboFits must already be populated (e.g. via
        % mdlObj_fromState or a prior fitByCombo call) before calling this;
        % it restores each child's weights in place via that child's own
        % loadFit, matched to its saved subfolder by combo key (not index —
        % robust to comboFits being reconstructed in a different order than
        % it was saved in) rather than fitting anything itself.
            if isempty(mdlObj.comboFits)
                mdlObj.loadFit(fitDir);
                return;
            end
            if nargin < 2 || isempty(fitDir)
                fitDir = uigetdir(pwd, sprintf('Select %s combo fit folder', mdlObj.modelID));
                if isequal(fitDir, 0), return; end
            end
            S        = load(fullfile(fitDir, 'comboManifest.mat'), 'manifest');
            manifest = S.manifest;
            for k = 1:numel(mdlObj.comboFits)
                idx = find(arrayfun(@(m) isequal(m.key, mdlObj.comboFits(k).key), manifest), 1);
                if isempty(idx)
                    fprintf('[mdlObject] loadFitAll: no saved fit found for combo %d — skipping.\n', k);
                    continue;
                end
                mdlObj.comboFits(k).child.loadFit(fullfile(fitDir, manifest(idx).folder));
            end
            mdlObj.fitPath = fitDir;
            fprintf('[mdlObject] loadFitAll: loaded %d combo fit(s) from %s\n', ...
                    numel(mdlObj.comboFits), fitDir);
        end

        function inspectGeometry(mdlObj, nexObj)
            % attach to state-space obj and visualize state-outputs
            % use mask-selection panel to visualize dropout of specific dim
            % combinations in latent space
        end

        function state = saveState(mdlObj)
        % Serialize the object's configuration into a plain struct (no handles).
        % Saved state + fitPath is the full contract for headless reconstruction.
        % Weights (W, Scaler, Reducer, model) live at fitPath — not included here.
            state.className   = class(mdlObj);
            state.modelID     = char(mdlObj.modelID);
            state.headline    = char(mdlObj.headline);
            state.dfID_source = char(mdlObj.dfID_source);
            state.dfID_target = char(mdlObj.dfID_target);
            state.fitPath     = char(mdlObj.fitPath);
            state.domain      = mdlObj_serializeDomain(mdlObj.domain);
            state.cfg         = nex_serializeCfg(mdlObj.cfg);
            state.collector   = mdlObj_serializeCollector(mdlObj.collector);
            % comboFits — one entry per fitByCombo() child, each recursively
            % dehydrated via its own saveState() (same contract as this
            % method: config only, no weights — those still live at each
            % child's own fitPath, restored separately via loadFit, same
            % as the top-level object). Empty whenever domain.CTG isn't
            % populated, matching mdlObj.comboFits itself.
            state.comboFits = struct('key', {}, 'state', {});
            for k = 1:numel(mdlObj.comboFits)
                state.comboFits(k).key   = mdlObj.comboFits(k).key;
                state.comboFits(k).state = mdlObj.comboFits(k).child.saveState();
            end
        end

        function STAT = applyPointer(mdlObj, STAT)
        % Slice STAT.df along any axis where the Pointer bus has a
        % multi-item selection.  Single-item selections (initSel=1 default)
        % are treated as "no window" so the default state is pass-through.
            bus      = mdlObj.collector.Pointer;
            axFields = fieldnames(bus.selections);
            anyChanged = false;

            % needsHR mdlObjs defer FTR-axis (reduce-mode) and pool-axis
            % narrowing to the DM level (applyPointerDM, driven by
            % nexAnalysis_cvPermute's swpAxes construction) instead of
            % here. Block-PCA (nexHR_fit) needs every raw unit within a
            % region to fit its per-block model, and any later
            % nexHR_transform call (flattenInput included) expects data at
            % that SAME full width the model was fitted against — slicing
            % chans/unit (or the pool axis) here, pre-reduction, breaks
            % both, even when Pointer's selKeys happen to type-match
            % STAT's raw values (the case the pre-existing type-mismatch
            % skip below doesn't catch). Same needsHR formula as
            % nexOp_compileSTAT/initReducer/nexAnalysis_cvPermute.
            needsHR = false;
            skipAxes = strings(0);
            if ~isempty(mdlObj.pMap)
                pmFields = fieldnames(mdlObj.pMap);
                needsHR  = any(arrayfun(@(i) mdlObj.pMap.(pmFields{i}).divsPerBin < 0, 1:numel(pmFields)));
                if needsHR
                    ftrAxis  = string(char(mdlObj.domain.FTR(1)));
                    skipAxes = ftrAxis;
                    coIdx    = nexOp_coIndexPairs(STAT.ax(1));
                    for p = 1:numel(coIdx)
                        if ismember(ftrAxis, string(coIdx{p}))
                            skipAxes = [skipAxes, string(coIdx{p})]; %#ok<AGROW>
                        end
                    end
                    for i = 1:numel(pmFields)
                        if mdlObj.pMap.(pmFields{i}).divsPerBin > 0
                            skipAxes = [skipAxes, string(pmFields{i})]; %#ok<AGROW>
                        end
                    end
                end
            end

            % Every row's own ax.(f) is resolved and sliced INDEPENDENTLY
            % below (no row-1-as-template / repmat-to-every-row) — some
            % axes (t, f, after pooling) genuinely share identical values
            % across every row, but others (a cross-subject-canonicalized
            % REG axis like chans/unit, where nexOp_alignCoAxes/
            % nexOp_compileSTAT deliberately canonicalize PER SUBJECT, not
            % globally) do NOT, and different subjects can have a
            % different true axis length (e.g. 18 vs 20 regions).
            % Confirmed directly: the old row-1-template version froze
            % EVERY row's ax.chans to row 1's own (sliced) 18-entry list
            % while STAT.df's actual per-row array width kept its own
            % correct, varying size (17/19/20/24) — ax and df silently
            % disagreeing about shape for every row but the first.
            for i = 1:numel(axFields)
                f      = axFields{i};
                if needsHR && any(skipAxes == string(f)), continue; end
                selIdx = bus.selections.(f);

                % Default (scalar 1) or single item → skip
                if numel(selIdx) <= 1, continue; end

                allVals      = bus.selKeys.(f);
                selectedVals = allVals(selIdx);
                if numel(selectedVals) == numel(allVals), continue; end

                if ~isfield(STAT.ax(1), f) || ~isprop(STAT.ptr(1), f)
                    continue;
                end

                dim = STAT.ptr(1).(f).dim;   % structural (which array dim owns this axis) — same role for every row
                fAnyChanged = false;
                for r = 1:height(STAT)
                    statVals = STAT.ax(r).(f);
                    if isnumeric(selectedVals) && isnumeric(statVals)
                        scale = max(abs(double(statVals(:))));
                        if scale == 0, scale = 1; end
                        [tf, loc] = ismembertol(double(selectedVals(:)), double(statVals(:)), ...
                                                1e-3, 'DataScale', scale);
                        dimIdx = sort(loc(tf));
                    elseif isnumeric(selectedVals) ~= isnumeric(statVals)
                        % Pointer bus type doesn't match STAT's axis type for this
                        % axis (e.g. bus.selKeys still numeric/raw, STAT.ax already
                        % pooled to string labels, or vice versa) — the bus is
                        % stale relative to the current pMap config. Skip windowing
                        % for this axis rather than crashing on an incomparable
                        % ismember call; surface it so it's visible, not silent.
                        % (needsHR mdlObjs are expected to hit this — that path
                        % filters via SWP/Pointer-selection intersection at the
                        % reduced/pooled DM level instead, see
                        % nexAnalysis_cvPermute's swpAxes construction.)
                        if r == 1
                            fprintf(['[mdlObject] applyPointer: axis "%s" type mismatch ' ...
                                     '(Pointer=%s vs STAT=%s) — Pointer bus is likely stale ' ...
                                     'relative to current pooling; skipping windowing for this axis.\n'], ...
                                     f, class(selectedVals), class(statVals));
                        end
                        continue;
                    else
                        % Every position whose value is in the selected set —
                        % not the first match per selected value. Two-output
                        % ismember(selectedVals, statVals) would return only one
                        % index per query value, silently dropping every other
                        % position sharing a repeated label (e.g. a region name
                        % that now labels many raw units after reduce-mode
                        % relabeling) — exactly the bug this replaces.
                        dimIdx = find(ismember(string(statVals), string(selectedVals)));
                    end
                    if isempty(dimIdx) || numel(dimIdx) == numel(statVals), continue; end

                    if isempty(dim)
                        % Co-indexed label: propagate mask to sibling with a real dimension.
                        coMasks  = nexOp_coAlign(STAT.ax(r), f, dimIdx);
                        coFields = fieldnames(coMasks);
                        newAx    = STAT.ax(r);
                        slicedSibling = false;
                        for ci = 1:numel(coFields)
                            coF = coFields{ci};
                            if strcmp(coF, f) || ~isfield(newAx, coF), continue; end
                            try, coDim = STAT.ptr(r).(coF).dim; catch, continue; end
                            if isempty(coDim), continue; end
                            STAT.df{r}  = ptrSliceDim(STAT.df{r}, coDim, dimIdx);
                            newAx.(coF) = newAx.(coF)(dimIdx);
                            slicedSibling = true;
                        end
                        if slicedSibling
                            newAx.(f)  = statVals(dimIdx);
                            STAT.ax(r) = newAx;
                            fAnyChanged = true;
                        end
                        continue;
                    end
                    STAT.df{r} = ptrSliceDim(STAT.df{r}, dim, dimIdx);

                    newAx   = STAT.ax(r);
                    preLen  = numel(statVals);
                    newAx.(f) = statVals(dimIdx);
                    % Keep co-indexed labels (e.g. per-unit 'chans') aligned.
                    newAx   = sliceCoIndexLabels(newAx, f, preLen, dimIdx);
                    STAT.ax(r) = newAx;
                    fAnyChanged = true;
                end
                if fAnyChanged
                    fprintf('[mdlObject] applyPointer: %s  [sliced per-row]\n', f);
                    anyChanged = true;
                end
            end

            if anyChanged
                % Per-row ptr rebuild — a broadcast-from-row-1 repmat here
                % would reintroduce the exact same row-1-template bug for
                % .ptr that the loop above was just fixed for .ax (ptr's
                % own .range/.value are tied to each axis's real length,
                % which can now legitimately differ row to row).
                ptrList = cell(height(STAT), 1);
                for r = 1:height(STAT)
                    DF_r = table2struct(STAT(r,:));
                    DF_r = rmfield(DF_r, 'ptr');
                    DF_r = nex_initAxisPointer_v2(DF_r);
                    ptrList{r} = DF_r.ptr;
                end
                STAT.ptr = vertcat(ptrList{:});
            end
        end

        function DF = applyPointerDF(mdlObj, DF)
        % Slice a single DF struct along axes where collector.Pointer has a
        % non-trivial selection.  Single-item default selections are pass-through.
            bus = mdlObj.collector.Pointer;
            if isempty(bus), return; end
            axFields = fieldnames(bus.selections);
            if isempty(axFields), return; end
            if ~isfield(DF,'ptr') || isempty(DF.ptr)
                % DF = nex_initAxisPointer_v2(DF);
                DF.ptr = nexInit_axisPointer(DF.df, DF.ax);
            end
            anyChanged = false;
            for ai = 1:numel(axFields)
                f      = axFields{ai};
                selIdx = bus.selections.(f);
                if numel(selIdx) <= 1, continue; end
                allVals      = bus.selKeys.(f);
                selectedVals = allVals(selIdx);
                if ~isfield(DF.ax, f), continue; end
                axVals = DF.ax.(f);
                if numel(selectedVals) == numel(axVals), continue; end
                if isnumeric(selectedVals) && isnumeric(axVals)
                    sc = max(abs(double(axVals(:)))); if sc == 0, sc = 1; end
                    [tf2, loc] = ismembertol(double(selectedVals(:)), double(axVals(:)), ...
                                             1e-3, 'DataScale', sc);
                    dimIdx = sort(loc(tf2));
                else
                    % Same fix as applyPointer: every position whose value
                    % is in the selected set, not just the first match per
                    % selected value (two-output ismember(selectedVals,
                    % axVals) would silently drop every other position
                    % sharing a repeated label).
                    dimIdx = find(ismember(string(axVals), string(selectedVals)));
                end
                if isempty(dimIdx) || numel(dimIdx) == numel(axVals), continue; end
                dim = DF.ptr.(f).dim;
                if isempty(dim)
                    % Co-indexed label (e.g. 'chans' riding on 'unit' dim).
                    % Propagate mask to the sibling axis that owns the DF dimension.
                    coMasks = nexOp_coAlign(DF, f, dimIdx);
                    coFields = fieldnames(coMasks);
                    slicedSibling = false;
                    for ci = 1:numel(coFields)
                        coF = coFields{ci};
                        if strcmp(coF, f) || ~isfield(DF.ax, coF), continue; end
                        try, coDim = DF.ptr.(coF).dim; catch, continue; end
                        if isempty(coDim), continue; end
                        S = repmat({':'}, 1, ndims(DF.df)); S{coDim} = dimIdx;
                        DF.df       = DF.df(S{:});
                        DF.ax.(coF) = DF.ax.(coF)(dimIdx);
                        slicedSibling = true;
                    end
                    if slicedSibling
                        DF.ax.(f) = axVals(dimIdx);
                        fprintf('[mdlObject] applyPointerDF: %s (co-idx)  [%d → %d]\n', ...
                                f, numel(axVals), numel(dimIdx));
                        anyChanged = true;
                    end
                    continue;
                end
                S = repmat({':'}, 1, ndims(DF.df)); S{dim} = dimIdx;
                DF.df      = DF.df(S{:});
                preLen     = numel(axVals);
                DF.ax.(f)  = axVals(dimIdx);
                % Keep co-indexed labels (e.g. per-unit 'chans') aligned.
                DF.ax      = sliceCoIndexLabels(DF.ax, f, preLen, dimIdx);
                fprintf('[mdlObject] applyPointerDF: %s  [%d → %d]\n', ...
                        f, numel(axVals), numel(dimIdx));
                anyChanged = true;
            end
            if anyChanged
                DF = nex_initAxisPointer_v2(DF);
            end
        end

        function vals = applyPointerDM(mdlObj, axisName, vals, ax)
        % DM-level counterpart to applyPointer: narrows a caller-supplied
        % candidate SWP value list (already resolved to reduce/pool
        % granularity — one label per block, or one bin-ID per window) down
        % to whatever the user currently has selected in the Pointer bus,
        % instead of slicing raw STAT/DF positions.
        %
        % applyPointer itself can't do this narrowing for a needsHR axis,
        % because STAT is still fully raw (unreduced/unpooled) at the point
        % applyPointer runs — its own type-mismatch guard always skips
        % these axes for that reason (see applyPointer's comment above).
        % Filtering here instead, against values already at the SAME
        % granularity as the SWP sweep itself, avoids that mismatch
        % entirely rather than patching around it. Used by
        % nexAnalysis_cvPermute's swpAxes construction.
        %
        %   axisName : SWP axis name (char/string) — checked directly
        %              against the Pointer bus, then via its co-indexed
        %              sibling (e.g. FTR's "unit" -> Pointer's "chans"),
        %              the same registry nexOp_resolvePMapEntry uses
        %              (nexOp_coIndexPairs).
        %   vals     : candidate SWP values for this axis (block labels or
        %              window bin-IDs), already resolved to post-reduce/
        %              post-pool granularity by the caller.
        %   ax       : a representative STAT.ax struct, for
        %              nexOp_coIndexPairs.
        %
        %   vals     : narrowed to the Pointer selection's intersection
        %              with the input; unchanged if Pointer has no
        %              non-default selection for this axis (or no matching
        %              field at all).
            bus = mdlObj.collector.Pointer;
            f = char(axisName);
            if ~isfield(bus.selections, f)
                coIdx = nexOp_coIndexPairs(ax);
                for p = 1:numel(coIdx)
                    pair = coIdx{p};
                    if ~ismember(f, pair), continue; end
                    for m = 1:numel(pair)
                        cand = char(pair{m});
                        if strcmp(cand, f), continue; end
                        if isfield(bus.selections, cand)
                            f = cand;
                            break;
                        end
                    end
                    if isfield(bus.selections, f), break; end
                end
            end
            if ~isfield(bus.selections, f), return; end

            selIdx = bus.selections.(f);
            if numel(selIdx) <= 1, return; end  % default (scalar 1) -> no-op

            allVals      = bus.selKeys.(f);
            selectedVals = allVals(selIdx);
            if numel(selectedVals) == numel(allVals), return; end  % select-all -> no-op

            if isnumeric(vals) && isnumeric(selectedVals)
                keep = ismember(vals, selectedVals);
            else
                keep = ismember(string(vals), string(selectedVals));
            end
            if ~any(keep)
                fprintf(['[mdlObject] applyPointerDM: axis "%s" Pointer selection ' ...
                         'matched none of the candidate values — leaving sweep ' ...
                         'unfiltered.\n'], f);
                return;
            end
            if ~all(keep)
                vals = vals(keep);
                fprintf('[mdlObject] applyPointerDM: axis "%s" narrowed to Pointer selection (%s)\n', ...
                        f, strjoin(string(vals), ', '));
            end
        end

        function initDomainBus(mdlObj)
        % Build collector.Domain: the D1 / FTR axis-role selectors plus, when a
        % residual axis remains (not DN / FTR / 'latent'), an MSR value-selector
        % over that axis's values. Mirrors the inline construction in the model
        % figures so the bus exists headlessly (fit path) and interactively.
        %
        % MSR is folded INTO Domain (no separate bus): a subset selection
        % (including a single value) COLLAPSES the residual axis; a full
        % selection loops over it (dormant until the fit path iterates slices).
        % Default = the "rate" value when present, else all-selected.
            if ~isstruct(mdlObj.collector), mdlObj.collector = struct(); end
            % Resolve source axes (names + values)
            srcAx = struct();
            try, srcAx = mdlObj.Origin.DF_postOp.ax; catch, end
            if isempty(fieldnames(srcAx))
                try
                    srcDF = dtsIO_readDF(mdlObj.nexon, mdlObj.dfID_source, []);
                    if ~isempty(srcDF) && isfield(srcDF, 'ax'), srcAx = srcDF.ax; end
                catch
                end
            end
            axNames = string(fieldnames(srcAx))';
            if isempty(axNames), axNames = "t"; end

            % DN options include "None" (trial-as-sample; DN permute skipped).
            % DN allows multi-select — the model trains/is scored jointly
            % across every selected axis (scoring itself still only resolves
            % DN(1); see nexAnalysis_cvPermute).
            dnOptions = ["None", axNames];
            dnInit    = find(ismember(dnOptions, mdlObj.domain.DN));
            if isempty(dnInit), dnInit = 2; end   % default to first real axis
            dnName    = dnOptions(dnInit);

            ftrInit = find(ismember(axNames, string(mdlObj.domain.FTR)));
            if isempty(ftrInit), ftrInit = find(~ismember(axNames, dnName), 1); end
            if isempty(ftrInit), ftrInit = 1; end

            domainDict.DN  = dnOptions;
            domainDict.FTR = axNames;
            domainDict.REG = nexOp_computeREGOptions(axNames(ftrInit), srcAx);
            mdlObj.domain.REG = "None";

            % MSR value selector — only when "measure" is explicitly a residual axis
            mdlObj.domain.MSRaxis = "";
            mdlObj.domain.MSR     = string.empty;
            msrInit  = [];
            claimed  = [dnName, axNames(ftrInit), "latent"];
            residual = axNames(~ismember(axNames, claimed));
            if ismember("measure", residual)
                rax   = "measure";
                rvals = srcAx.(rax);
                if ~isempty(rvals)
                    domainDict.MSR        = rvals;
                    mdlObj.domain.MSRaxis = rax;
                    rIdx = find(string(rvals) == "rate", 1);
                    if isempty(rIdx), msrInit = 1:numel(rvals); else, msrInit = rIdx; end
                    mdlObj.domain.MSR = string(rvals(msrInit));
                end
            end

            mdlObj.collector.Domain = buildSelection(mdlObj, domainDict);
            mdlObj.collector.Domain.selections.DN  = dnInit;
            mdlObj.collector.Domain.selections.FTR = ftrInit;
            mdlObj.collector.Domain.selections.REG = 1;   % default = "None"
            if ~isempty(msrInit)
                mdlObj.collector.Domain.selections.MSR = msrInit;
            end
            % Sync domain fields directly — the selection listboxes may not
            % exist yet at init time (headless, or pre-panel figure build).
            mdlObj.domain.DN  = dnName;
            mdlObj.domain.FTR = axNames(ftrInit);
        end

        function STAT = applyDomainMSR(mdlObj, STAT)
        % Collapse the residual (MSR) axis of every STAT.df to domain.MSR
        % values. Fit-side counterpart of applyDomainMSRDF; both share the
        % domainSliceAxis core. No-op when no MSR axis is configured.
            if ~isfield(mdlObj.domain,'MSRaxis') || mdlObj.domain.MSRaxis == "", return; end
            f = mdlObj.domain.MSRaxis;
            if ~isfield(mdlObj.domain,'MSR') || isempty(mdlObj.domain.MSR), return; end
            if ~isfield(STAT.ax(1), f) || ~isprop(STAT.ptr(1), f), return; end
            axVals = STAT.ax(1).(f);
            dim    = STAT.ptr(1).(f).dim;
            [~, keepIdx] = domainSliceAxis(STAT.df{1}, axVals, dim, mdlObj.domain.MSR);
            if numel(keepIdx) == numel(axVals), return; end   % pass-through
            STAT.df = cellfun(@(df) ptrSliceDim(df, dim, keepIdx), ...
                              STAT.df, 'UniformOutput', false);
            % Update ONLY the MSR field per row — not replace each row's
            % whole ax struct with row 1's. The MSR axis itself (e.g.
            % 'measure') is the same set of kept values for every row, but
            % OTHER fields (REG/FTR included) can legitimately differ per
            % row when STAT spans subjects with different per-subject
            % canonical widths — broadcasting row 1's full ax struct here
            % silently overwrote every other row's own chans/unit values
            % with row 1's subject's, right after compileSTAT()'s own
            % per-row restore had just fixed exactly that.
            newF = axVals(keepIdx);
            for ri = 1:height(STAT)
                STAT.ax(ri).(f) = newF;
            end
            fprintf('[mdlObject] applyDomainMSR: %s  [%d -> %d]\n', ...
                    f, numel(axVals), numel(keepIdx));
            DF_ptr = table2struct(STAT(1,:)); DF_ptr = rmfield(DF_ptr,'ptr');
            DF_ptr = nex_initAxisPointer_v2(DF_ptr);
            STAT.ptr = repmat(DF_ptr.ptr, height(STAT), 1);
        end

        function DF = applyDomainMSRDF(mdlObj, DF)
        % Single-DF counterpart (transform / scaleApply path). Shares the
        % domainSliceAxis core with applyDomainMSR.
            if ~isfield(mdlObj.domain,'MSRaxis') || mdlObj.domain.MSRaxis == "", return; end
            f = mdlObj.domain.MSRaxis;
            if ~isfield(mdlObj.domain,'MSR') || isempty(mdlObj.domain.MSR), return; end
            if ~isfield(DF,'ptr') || isempty(DF.ptr), DF = nex_initAxisPointer_v2(DF); end
            if ~isfield(DF.ax, f) || ~isprop(DF.ptr, f), return; end
            axVals = DF.ax.(f);
            dim    = DF.ptr.(f).dim;
            [DF.df, keepIdx] = domainSliceAxis(DF.df, axVals, dim, mdlObj.domain.MSR);
            if numel(keepIdx) == numel(axVals), return; end   % pass-through
            DF.ax.(f) = axVals(keepIdx);
            DF = nex_initAxisPointer_v2(DF);
        end

        function Y_pred = predict(mdlObj, X_raw)
        % Scale X_raw (if Scaler is fitted) then call model.predict.
        % Returns strings for classifiers (decoding via W.labelKey when the model
        % was trained on integer codes) and doubles for regression models.
            np    = py.importlib.import_module('numpy');
            X     = X_raw;
            nFeat = size(X_raw, 2);
            % MATLAB's py.* conversion can collapse a genuine [n_samples x 1]
            % column (e.g. a single surviving feature after a Pointer filter
            % narrows a SWP group down to one unit) into a 1-D (n,) NumPy
            % array — sklearn's transform/predict reject 1-D input outright.
            % Force the shape explicitly using nFeat computed from the
            % MATLAB side (always reliable), rather than trusting the
            % conversion to have preserved it. Same fix as nexFit_lda.m.
            if isstruct(mdlObj.Scaler) && isfield(mdlObj.Scaler, 'model') && ...
                    ~isempty(mdlObj.Scaler.model)
                X_py = np.array(X).reshape(int32(-1), int32(nFeat));
                X    = double(mdlObj.Scaler.model.transform(X_py));
            end
            X_py = np.array(X).reshape(int32(-1), int32(nFeat));
            Y_py = mdlObj.model.predict(X_py);
            try
                Y_pred = double(Y_py);
            catch
                Y_pred = string(cellfun(@char, cell(Y_py), 'UniformOutput', false));
                return;
            end
            % Decode integer codes → string labels when fit used label encoding
            if isstruct(mdlObj.W) && isfield(mdlObj.W, 'labelKey') && ...
                    ~isempty(mdlObj.W.labelKey)
                key = mdlObj.W.labelKey;
                [~, idx] = ismember(Y_pred, double(key.code));
                Y_pred = string(key.label(idx));
            end
        end

        function storeResult(mdlObj, resultID, R)
        % Store R under RESULTS.(resultID) and push to any connected viewer.
            mdlObj.RESULTS.(resultID) = R;
            if isstruct(mdlObj.Partners) && isfield(mdlObj.Partners, 'viewer') && ...
                    ~isempty(mdlObj.Partners.viewer) && isvalid(mdlObj.Partners.viewer)
                mdlObj.Partners.viewer.push(resultID, R);
            end
        end

        function applySRC(mdlObj, srcKeys)
        % Dispatch to Figure.renderFcns.(activeTab) when available.
            if isempty(mdlObj.Figure) || ~isfield(mdlObj.Figure, 'renderFcns'), return; end
            if ~isstruct(mdlObj.Figure.renderFcns),                             return; end
            if ~isfield(mdlObj.Figure.renderFcns, 'active'),                   return; end
            tab = mdlObj.Figure.renderFcns.active;
            if isfield(mdlObj.Figure.renderFcns, tab)
                mdlObj.Figure.renderFcns.(tab)(srcKeys);
            end
        end

    end
end

% ── Local serialization helpers ───────────────────────────────────────────────

function dom = mdlObj_serializeDomain(domain)
    dom = struct();
    if isempty(domain), return; end
    fields = fieldnames(domain);
    for i = 1:numel(fields)
        f   = fields{i};
        val = domain.(f);
        if isstring(val) || ischar(val) || isnumeric(val)
            dom.(f) = val;
        end
    end
end

function col = mdlObj_serializeCollector(collector)
    col = struct();
    if isempty(collector), return; end
    fields = fieldnames(collector);
    for i = 1:numel(fields)
        f   = fields{i};
        val = collector.(f);
        if isa(val, 'nexObj_selectionBus')
            col.(f) = nex_returnSelectionMask(val);
        elseif isstruct(val)
            col.(f) = mdlObj_serializePrimitives(val);
        elseif isstring(val) || ischar(val) || isnumeric(val) || islogical(val)
            col.(f) = val;
        end
    end
end

function out = mdlObj_serializePrimitives(s)
    out = struct();
    fields = fieldnames(s);
    for i = 1:numel(fields)
        f   = fields{i};
        val = s.(f);
        if isstring(val) || ischar(val) || isnumeric(val) || islogical(val)
            out.(f) = val;
        elseif isstruct(val)
            out.(f) = mdlObj_serializePrimitives(val);
        end
    end
end

function X = ptrSliceDim(A, dim, idx)
    S      = repmat({':'}, 1, ndims(A));
    S{dim} = idx;
    X      = A(S{:});
end

function ax = sliceCoIndexLabels(ax, siblingField, siblingLen, idx)
% When a sibling axis (e.g. 'unit') is windowed to idx, slice any co-indexed
% label (dim=[], same length) that rides along it (e.g. per-unit 'chans') to the
% same indices, so the label stays aligned with its sibling.
    coLabels = nex_coIndexAxisLabels();
    lf = fieldnames(ax);
    for i = 1:numel(lf)
        f = lf{i};
        if strcmp(f, siblingField) || ~ismember(string(f), coLabels), continue; end
        if numel(ax.(f)) == siblingLen
            ax.(f) = ax.(f)(idx);
        end
    end
end

function [df, keepIdx] = domainSliceAxis(df, axVals, dim, keepVals)
% Shared Domain/MSR slice core. Returns the indices of axVals whose values
% are in keepVals (numeric → tolerant match; else exact membership) and
% slices df along `dim` to them. Empty or full match ⇒ pass-through: df is
% returned unchanged and keepIdx spans the whole axis.
    if isnumeric(keepVals) && isnumeric(axVals)
        sc = max(abs(double(axVals(:)))); if sc==0, sc=1; end
        [tf,loc] = ismembertol(double(keepVals(:)), double(axVals(:)), 1e-3, 'DataScale', sc);
        keepIdx  = sort(loc(tf));
    else
        [~,keepIdx] = ismember(keepVals, axVals);
        keepIdx     = sort(keepIdx(keepIdx>0));
    end
    if isempty(keepIdx) || numel(keepIdx) == numel(axVals)
        keepIdx = (1:numel(axVals))';
        return;                       % pass-through: df unchanged
    end
    S = repmat({':'}, 1, ndims(df)); S{dim} = keepIdx;
    df = df(S{:});
end

function mdlObject_restoreHeadless(nexon, wasHeadless)
% onCleanup target for fitByCombo -- a plain statement assignment, which
% an anonymous function body cannot contain directly (must be a single
% expression), so this tiny wrapper is the mechanism. nexon is a handle;
% mutating its .settings.headless field here reaches the SAME shared
% Nexon instance fitByCombo toggled, exactly like the old inline
% assignment did.
    nexon.settings.headless = wasHeadless;
end

function child = mdlObject_initGridChild(mdlObj, initFcn)
% Construct one grid-cell child mdlObj and inherit mdlObj's own
% domain/pMap/cfg/collector/fitSentinel -- the exact construction skeleton
% fitByCombo used per combo, factored out here since fitSWPGrid now needs
% it at THREE levels (per CTG combo, and again per SWP grid cell within
% each combo) instead of once.
%
%   mdlObj  : the top-level mdlObj fitSWPGrid was called on (NOT the
%             immediate parent cell -- predictorID/Parent/Origin/
%             dfID_source always come from the top level)
%   initFcn : str2func(class(mdlObj))
    if strcmpi(mdlObj.modelID, 'lda')
        child = initFcn(mdlObj.Parent, mdlObj.Origin, mdlObj.dfID_source, mdlObj.predictorID);
    else
        child = initFcn(mdlObj.Parent, mdlObj.Origin, mdlObj.dfID_source);
    end
    child.domain      = mdlObj.domain;
    child.pMap        = mdlObj.pMap;
    child.cfg         = mdlObj.cfg;
    child.collector   = mdlObj.collector;
    child.fitSentinel = mdlObj.fitSentinel;
end

function mdlObj_h5ClearGroup(h5File, groupPath)
% Unlink groupPath (and everything under it) from h5File if present. Used by
% scaleApply_transform to clear a row's prior transform output before a fresh
% write, so re-runs don't leave stale datasets from an earlier (differently
% shaped) DF. No-op if the file or group doesn't exist yet.
    if ~exist(h5File, 'file'), return; end
    fapl = H5P.create('H5P_FILE_ACCESS');
    H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
    fid = H5F.open(h5File, 'H5F_ACC_RDWR', fapl);
    H5P.close(fapl);
    try
        if H5L.exists(fid, groupPath, 'H5P_DEFAULT')
            H5L.delete(fid, groupPath, 'H5P_DEFAULT');
        end
    catch
    end
    H5F.close(fid);
end