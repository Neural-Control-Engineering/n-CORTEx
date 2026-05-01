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
                STAT_test = mdlObj.STAT(mdlObj.trainMask==0,:);
            else
                STAT_train=mdlObj.STAT;
                STAT_test=[];
            end
            mdlObj.TEST.STAT=STAT_test;
            mdlObj.TRAIN.STAT=STAT_train;
            % compile design matrix
            dmFcn = str2func(sprintf("stat2dm_%s",mdlObj.cfg.dmCfg.format));
            mdlObj.DM = dmFcn(mdlObj);
            % mdlObj.DM = mdlObj.cfg.dmCfg.fcn(mdlObj, dmArgs);
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

        function scaleApply_transform(mdlObj, dfID_source, isOverwrite)

            % CFG HEADER
            scope = "global"; % scope : global/local

            % apply fit transform row-by-row — avoids loading entire column into memory
            if nargin < 2
                dfID_source = mdlObj.dfID_source; % use original dfID_source
                isOverwrite = 0; % don't overwrite source
            end
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
            rowIdxs = find(idxSel==1);
            % for i = 1:dtsRows
            for r=1:length(rowIdxs)
                i=rowIdxs(r);
                fprintf("row: %d \n",i);
                sessionLabel = mdlObj.nexon.console.BASE.DTS.sessionLabel{i};
                disp(sessionLabel);
                DF_X = dtsIO_readDF(mdlObj.nexon, dfID_entry, i);
                if ~isfield(DF_X,"df")
                    continue
                end
                if isempty(DF_X) || isempty(DF_X.df)
                    continue
                end
                DF_X = nex_initAxisPointer_v2(DF_X);
                DF_X = nexOp_permute2First(DF_X, d1Sel, DF_X.ptr);
                try
                    DF_Z = mdlObj.transform(DF_X);
                catch e
                    disp(getReport(e));
                    continue
                end
                if isempty(DF_Z) || isempty(DF_Z.df)
                    continue
                end
                switch isOverwrite
                    case 0 
                        dtsIO_writeDF(mdlObj.nexon, DF_Z, mdlObj.dfID_target, i);
                    case 1
                        dtsIO_writeDF(mdlObj.nexon, DF_Z, dfID_entry, i);
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
            % place primary dim first
            STAT.df = cellfun(@(df) nexOp_permute2First(df, d1Sel, ptr), STAT.df, "UniformOutput", false);        
            % broadcast new pointer after permute
            DF_ptr = table2struct(STAT(1,:)); DF_ptr = rmfield(DF_ptr,"ptr");
            DF_ptr =nex_initAxisPointer_v2(DF_ptr);
            STAT.ptr = repmat(DF_ptr.ptr,height(STAT),1);

            % Apply Pointer window if user has made an axis selection
            if isfield(mdlObj.collector, 'Pointer') && ~isempty(mdlObj.collector.Pointer)
                STAT = mdlObj.applyPointer(STAT);
            end

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
                newAx.(f) = statVals(dimIdx);
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