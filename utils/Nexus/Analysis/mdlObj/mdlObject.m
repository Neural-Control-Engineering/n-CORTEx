classdef mdlObject < handle

    properties
        headline
        fitPath      % absolute path to saveFit folder — set by saveFit/loadFit
        RESULTS = struct()   % model-diagnostic results (CV scores, eigenspectra, ...)
        nexon
        modelID
        predictorID
        model
        Reducer
        PoolReducer
        HR          % nexHR model tree — nested cell from nexHR_fit (empty when not used)
        FTR_layout  % struct array [{axID,n},...] outermost-first, built by buildFTRLayout
        Scaler
        Predictor
        W % fit weights
        DM % design matrix
        py = struct(); % stored pymodules
        CV % cross validation group
        STAT % stat table with training samples (dereference-able file locations of samples)
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
            % DOMAIN INIT
            try
                mdlObj.domain = nexInit_domain(mdlObj.Origin.DF_postOp);
            catch
                mdlObj.domain = nexInit_domain([]);
            end
            % Build Figure (skipped in headless mode)
            isHeadless = isfield(mdlObj.nexon, 'settings') && ...
                         isfield(mdlObj.nexon.settings, 'headless') && ...
                         mdlObj.nexon.settings.headless;
            if ~isHeadless
                figFcn = str2func(sprintf("nexFigure_%s", mdlObj.modelID));
                figFcn(mdlObj);
                mdlObj.applyHeadline();
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
            if isfield(sel, 'D1')  && ~isempty(sel.D1),  mdlObj.domain.D1  = string(sel.D1);  end
            if isfield(sel, 'FTR') && ~isempty(sel.FTR), mdlObj.domain.FTR = string(sel.FTR); end
            if isfield(sel, 'MSR') && ~isempty(sel.MSR), mdlObj.domain.MSR = string(sel.MSR); end
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
                mdlObj.nexon, pan_ptr, mdlObj.collector.Pointer, []);
        end

        function applyHeadline(mdlObj)
            if ~isempty(mdlObj.headline) && isfield(mdlObj.Figure, 'fh') && isvalid(mdlObj.Figure.fh)
                mdlObj.Figure.fh.Name = mdlObj.headline;
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
            % compile design matrix (ND: first dim = samples, rest = FTR axes)
            dmFcn     = str2func(sprintf("stat2dm_%s", mdlObj.cfg.dmCfg.format));
            mdlObj.DM = dmFcn(mdlObj);
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
            d1Sel = string(mdlObj.domain.D1(1));
            axNames  = string(fieldnames(ax_s))';
            ftrAxes  = axNames(axNames ~= d1Sel & axNames ~= "None");
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
            layout   = arrayfun(@(ax, n) struct('axID', char(ax), 'n', double(n)), ftrAxes, ns);
        end

        function initReducer(mdlObj)
        % Base: fit nexHR when any FTR axis has negative divsPerBin.
        % Otherwise flatten DM to 2D. Subclasses may override (SSM does).
            if isempty(mdlObj.DM), return; end
            layout   = mdlObj.FTR_layout;
            needsHR  = ~isempty(layout) && ~isempty(mdlObj.pMap) && ...
                any(arrayfun(@(e) isfield(mdlObj.pMap, e.axID) && ...
                                  mdlObj.pMap.(e.axID).divsPerBin < 0, layout));
            if needsHR
                useGPU = isfield(mdlObj, 'cfg') && isfield(mdlObj.cfg, 'fitCfg') && ...
                         isfield(mdlObj.cfg.fitCfg, 'entryParams') && ...
                         isfield(mdlObj.cfg.fitCfg.entryParams, 'useGPU') && ...
                         mdlObj.cfg.fitCfg.entryParams.useGPU;
                [mdlObj.DM, mdlObj.HR] = nexHR_fit(mdlObj.DM, layout, mdlObj.pMap, useGPU);
            else
                mdlObj.DM = reshape(mdlObj.DM, size(mdlObj.DM, 1), []);
            end
        end

        function X_flat = flattenInput(mdlObj, DF_X)
        % Convert a raw (post-pool, D1-first) ND DF to a 2D feature matrix.
        % Uses nexHR_transform when an HR model is fitted; otherwise plain reshape.
        % Called at the top of every subclass transform — subclasses need not know
        % whether nexHR was used.
            X = DF_X.df;
            if ~isempty(mdlObj.HR)
                if mdlObj.domain.D1 == "None"
                    X = reshape(X, [1, size(X)]);  % single-trial: add N_ctx=1 to match fit shape
                end
                X_flat = nexHR_transform(X, mdlObj.FTR_layout, mdlObj.pMap, mdlObj.HR);
            else
                X_flat = reshape(X, size(X, 1), []);
            end
        end

        function fit(mdlObj)
            % inherit STAT
            % if isempty(mdlObj.STAT)
            mdlObj.compileSTAT(); 
            % end
            % prepare DM
            mdlObj.getDesignMatrix();
            % apply training assembly on stored dataset
            fitArgs = mdlObj.cfg.fitCfg.entryParams;
            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
            % train predictor (if predictor is disjointed)         
            if ~isempty(mdlObj.Predictor)
                if ~isequal(mdlObj,mdlObj.Predictor)
                    mdlObj.Predictor.trainMask=mdlObj.trainMask;
                    mdlObj.Predictor.fit(); % or child
                end
            end
            mdlObj.DM=[];
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

        function scaleApply_transform(mdlObj, dfID_source, isOverwrite, currentTrialOnly)

            % CFG HEADER
            scope = "local"; % scope : global/local

            % apply fit transform row-by-row — avoids loading entire column into memory
            if nargin < 2 || isempty(dfID_source),   dfID_source    = mdlObj.dfID_source; end
            if nargin < 3 || isempty(isOverwrite),   isOverwrite    = true;  end
            if nargin < 4 || isempty(currentTrialOnly), currentTrialOnly = false; end
            dfID_entry = strrep(dfID_source, "_df", "");
            d1Sel = mdlObj.domain.D1(1);
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
                if isfield(mdlObj.collector, 'Pointer') && ~isempty(mdlObj.collector.Pointer)
                    DF_X = mdlObj.applyPointerDF(DF_X);
                end
                DF_X = mdlObj.applyDomainMSRDF(DF_X);
                if d1Sel ~= "None"
                    DF_X = nexOp_permute2First(DF_X, d1Sel, DF_X.ptr);
                end
                if ~isempty(mdlObj.pMap)
                    DF_X = nexOp_poolAxes(mdlObj.pMap, DF_X, DF_X.ptr);
                end
                try
                    DF_Z = mdlObj.transform(DF_X);
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
                [STAT, idxSel, drop] = nexOp_compileSTAT(mdlObj, mdlObj.dfID_source, S_categories, S_items, []);
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
            [df_trim,ax_trim]=nexOp_trimTF(TF_STAT);
            d1Sel=mdlObj.domain.D1(1);
            STAT.df=df_trim;
            STAT.ax=arrayfun(@(ax) ax_trim, STAT.ax);
            ptr = STAT.ptr(1);
            % place primary dim first (skip when D1="None" — trial is the sample)
            if d1Sel ~= "None"
                STAT.df = cellfun(@(df) nexOp_permute2First(df, d1Sel, ptr), STAT.df, "UniformOutput", false);
            end        
            % broadcast new pointer after permute
            DF_ptr = table2struct(STAT(1,:)); DF_ptr = rmfield(DF_ptr,"ptr");
            DF_ptr =nex_initAxisPointer_v2(DF_ptr);
            STAT.ptr = repmat(DF_ptr.ptr,height(STAT),1);

            % Apply Pointer window if user has made an axis selection
            if isfield(mdlObj.collector, 'Pointer') && ~isempty(mdlObj.collector.Pointer)
                STAT = mdlObj.applyPointer(STAT);
            end

            % Collapse the residual (MSR) axis per the Domain bus selection
            STAT = mdlObj.applyDomainMSR(STAT);

            mdlObj.STAT=STAT;
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

        function DF_Y = predict(mdlObj, DF_X)
            % propagate transformation from input layer 
            Parent=mdlObj.Parent; parentClass=class(Parent);
            if contains(parentClass,"mdlObj")
                DF_X_tf = mdlObj.Predictor.Parent.transformInput(DF_X);
            else
                DF_X_tf=DF_X;
            end
            % predict transformed input
            np = py.importlib.import_module("numpy");
            X = DF_X_tf.df;
            X_py = np.array(X);
            Y_py = mdlObj.Predictor.model.predict_proba(X_py);                   
            % Y_py = mdlObj.predictor.model.predict(X_py);                    
            Y = double(Y_py);
            key = mdlObj.Predictor.DM.K.(mdlObj.Predictor.dfID_target);
            % logit_pt = log(Y./ (1 - Y));     % convert probabilities to log-odds
            % logit_smoothed = movmean(logit_pt, 50);
            % trial_prob = mean(1 ./ (1 + exp(-logit_smoothed)));
            % Y_label = double(mdlObj.predictor.model.classes_);
            % figure;plot(Y(1:end,:),'DisplayName','Y(1:4348,:)')
            % Y = find(mean(Y)==max(mean(Y)));
            DF_Y.df=Y;
            DF_Y.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);
            DF_Y.ax.(mdlObj.Predictor.dfID_target)=key.label';                        
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

        function saveFit(mdlObj, uniqueID)
            % Subclasses override. Creates a folder named mdlObj_{modelID}_{uniqueID}
            % and serializes all fit artifacts into it. Python objects must go
            % through Python (pickle / npz) — MATLAB save() cannot handle them.
        end

        function loadFit(mdlObj, fitDir)
            % Subclasses override. Restores fit artifacts from the folder
            % produced by saveFit.
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
        end

        function STAT = applyPointer(mdlObj, STAT)
        % Slice STAT.df along any axis where the Pointer bus has a
        % multi-item selection.  Single-item selections (initSel=1 default)
        % are treated as "no window" so the default state is pass-through.
            bus      = mdlObj.collector.Pointer;
            axFields = fieldnames(bus.selections);
            anyChanged = false;

            for i = 1:numel(axFields)
                f      = axFields{i};
                selIdx = bus.selections.(f);

                % Default (scalar 1) or single item → skip
                if numel(selIdx) <= 1, continue; end

                allVals      = bus.selKeys.(f);
                selectedVals = allVals(selIdx);
                if numel(selectedVals) == numel(allVals), continue; end

                if ~isfield(STAT.ax(1), f) || ~isprop(STAT.ptr(1), f)
                    continue;
                end

                statVals = STAT.ax(1).(f);
                if isnumeric(selectedVals) && isnumeric(statVals)
                    scale = max(abs(double(statVals(:))));
                    if scale == 0, scale = 1; end
                    [tf, loc] = ismembertol(double(selectedVals(:)), double(statVals(:)), ...
                                            1e-3, 'DataScale', scale);
                    dimIdx = sort(loc(tf));
                else
                    [~, dimIdx] = ismember(selectedVals, statVals);
                    dimIdx = sort(dimIdx(dimIdx > 0));
                end
                if isempty(dimIdx) || numel(dimIdx) == numel(statVals), continue; end

                dim     = STAT.ptr(1).(f).dim;
                STAT.df = cellfun(@(df) ptrSliceDim(df, dim, dimIdx), ...
                                  STAT.df, 'UniformOutput', false);

                newAx   = STAT.ax(1);
                preLen  = numel(statVals);
                newAx.(f) = statVals(dimIdx);
                % Keep co-indexed labels (e.g. per-unit 'chans') aligned.
                newAx   = sliceCoIndexLabels(newAx, f, preLen, dimIdx);
                STAT.ax = repmat(newAx, height(STAT), 1);

                fprintf('[mdlObject] applyPointer: %s  [%d → %d]\n', ...
                        f, numel(statVals), numel(dimIdx));
                anyChanged = true;
            end

            if anyChanged
                DF_ptr = table2struct(STAT(1,:));
                DF_ptr = rmfield(DF_ptr, 'ptr');
                DF_ptr = nex_initAxisPointer_v2(DF_ptr);
                STAT.ptr = repmat(DF_ptr.ptr, height(STAT), 1);
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
                    [~, dimIdx] = ismember(selectedVals, axVals);
                    dimIdx = sort(dimIdx(dimIdx > 0));
                end
                if isempty(dimIdx) || numel(dimIdx) == numel(axVals), continue; end
                dim = DF.ptr.(f).dim;
                if isempty(dim), continue; end  % co-indexed label (e.g. 'chans') — no own dimension
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

        function initDomainBus(mdlObj)
        % Build collector.Domain: the D1 / FTR axis-role selectors plus, when a
        % residual axis remains (not D1 / FTR / 'factor'), an MSR value-selector
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

            % D1 options include "None" (trial-as-sample; D1 permute skipped)
            d1Options = ["None", axNames];
            d1Init    = find(d1Options == mdlObj.domain.D1(1), 1);
            if isempty(d1Init), d1Init = 2; end   % default to first real axis
            d1Name    = d1Options(d1Init);

            ftrInit = find(ismember(axNames, string(mdlObj.domain.FTR)));
            if isempty(ftrInit), ftrInit = find(axNames ~= d1Name, 1); end
            if isempty(ftrInit), ftrInit = 1; end

            domainDict.D1  = d1Options;
            domainDict.FTR = axNames;

            % MSR value selector — only when "measure" is explicitly a residual axis
            mdlObj.domain.MSRaxis = "";
            mdlObj.domain.MSR     = string.empty;
            msrInit  = [];
            claimed  = [d1Name, axNames(ftrInit), "factor"];
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
            mdlObj.collector.Domain.selections.D1  = d1Init;
            mdlObj.collector.Domain.selections.FTR = ftrInit;
            if ~isempty(msrInit)
                mdlObj.collector.Domain.selections.MSR = msrInit;
            end
            % Sync domain fields directly — the selection listboxes may not
            % exist yet at init time (headless, or pre-panel figure build).
            mdlObj.domain.D1  = d1Name;
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
            newAx = STAT.ax(1); newAx.(f) = axVals(keepIdx);
            STAT.ax = repmat(newAx, height(STAT), 1);
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