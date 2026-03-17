classdef mdlObject < handle

    properties
        nexon
        modelID
        predictorID
        model
        predictor
        W % fit weights
        DM % design matrix
        py = struct(); % stored pymodules
        CV % cross validation group
        STAT % stat table with training samples (dereference-able file locations of samples)
        trainMask % mask training samples for cross validation
        targetVar
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
        UserData
    end

    methods
        function mdlObj = mdlObject(Parent, Origin, modelID, dfID_source, predictorID)             
            % cebra = py.importlib.import_module('cebra');
            % args = extractMethodCfg('model_cebra');
            % neural network handle to train and infer from a neural
            % mdlObj.modelObj = model_cebra(cebra, args);                        
            % network, etc.
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
            mdlObj.targetVar = "sessionLabel_phase"; % TEMPORARY
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
                    mdlObj.predictor = predInitFcn(mdlObj, Origin, mdlObj.dfID_target);
                else
                    mdlObj.predictor=mdlObj;
                end
            end
            % PARAMS INIT
            mdlObj.cfg.cvCfg.entryParams.numFolds=5;
            mdlObj.cfg.cvCfg.entryParams.isShuffle=0;
            mdlObj.cfg.dmCfg.format="stack";
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
            if isempty(mdlObj.STAT)
                mdlObj.compileSTAT(); 
            end
            % prepare DM
            mdlObj.getDesignMatrix();
            % apply training assembly on stored dataset
            fitArgs = mdlObj.cfg.fitCfg.entryParams;
            mdlObj.cfg.fitCfg.fcn(mdlObj, fitArgs);
            % train predictor (if predictor is disjointed)         
            if ~isempty(mdlObj.predictor)
                if ~isequal(mdlObj,mdlObj.predictor)
                    mdlObj.predictor.trainMask=mdlObj.trainMask;
                    mdlObj.predictor.fit(); % or child
                end
            end
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

        function scaleApply_transform(mdlObj)
            % apply fit transform to all samples in the dfID column
            % DF_Z = mdlObj.fit(DF_X)
            [TF_X, iLoc] = dtsIO_readTF(mdlObj.nexon, mdlObj.dfID_source, []);
            TF_X = cellfun(@(DF) nex_initAxisPointer_v2(DF), TF_X,"UniformOutput",false);
            % ptr = mdlObj.Parent.STAT.ptr(1);
            % ptr = mdlObj.STAT.ptr(1);
            d1Sel = mdlObj.domain.D1(1);
            % first check
            maskValid = cellfun(@(DF_X) ~isempty(DF_X), TF_X, "UniformOutput", true);
            TF_X(maskValid) = cellfun(@(DF) nexOp_permute2First(DF, d1Sel, DF.ptr), TF_X(maskValid), "UniformOutput", false);
            % second check
            % maskValid = cellfun(@(DF_X) ~isempty(DF_X.df), TF_X, "UniformOutput", true);
            TF_Z(maskValid) = cellfun(@(DF_X) mdlObj.transform(DF_X), TF_X(maskValid), "UniformOutput", false);
            TF_Z = TF_Z';
            maskValid = cellfun(@(DF) ~isempty(DF), TF_Z, "UniformOutput", true);
            maskValid(maskValid) = cellfun(@(DF) ~isempty(DF.df), TF_Z(maskValid), "UniformOutput", true)';
            ILOC = num2cell(iLoc);
            cellfun(@(DF_Z, idx) dtsIO_writeDF(mdlObj.nexon, DF_Z, mdlObj.dfID_target, idx), TF_Z(maskValid), ILOC(maskValid));
        end

        function compileSTAT(mdlObj)
            % use categorical parent selection to compile dfID_source relative STAT
            % table
            Parent = mdlObj.Parent;
            parentClass = class(Parent);
            if strcmp(parentClass,"nexObj_categorical") % if parent is categorical
                S_categories = nex_returnSelectionMask(Parent.selectionBus.categories);
                S_items = nex_returnSelectionMask(Parent.selectionBus.items);
                % STAT = nexOp_compileSTAT(mdlObj, mdlObj.dfID_source, S_categories, S_items, []);
                STAT = nexOp_compileSTAT(Parent, mdlObj.dfID_source, S_categories, S_items, []);
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
            stratVar = mdlObj.STAT.(mdlObj.targetVar);
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
            Y_true=mdlObj.TEST.STAT.(mdlObj.targetVar);
            TF_preds = mdlObj.TEST.STAT.prediction;
            % [TF_probs, TF_scores] = cellfun(@(DF) max(mean(DF.df,1)), TF_preds, "UniformOutput",false);
            [TF_probs] = cellfun(@(DF) (mean(DF.df,1)), TF_preds, "UniformOutput",false);
            TF_probs=cat(1,TF_probs{:});
            L=TF_preds{1}.ax.(mdlObj.targetVar);
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
                DF_X_tf = mdlObj.predictor.Parent.transformInput(DF_X);
            else
                DF_X_tf=DF_X;
            end
            % predict transformed input
            np = py.importlib.import_module("numpy");
            X = DF_X_tf.df;
            X_py = np.array(X);
            Y_py = mdlObj.predictor.model.predict_proba(X_py);                   
            % Y_py = mdlObj.predictor.model.predict(X_py);                    
            Y = double(Y_py);
            key = mdlObj.predictor.DM.K.(mdlObj.predictor.targetVar);
            % logit_pt = log(Y./ (1 - Y));     % convert probabilities to log-odds
            % logit_smoothed = movmean(logit_pt, 50);
            % trial_prob = mean(1 ./ (1 + exp(-logit_smoothed)));
            % Y_label = double(mdlObj.predictor.model.classes_);
            % figure;plot(Y(1:end,:),'DisplayName','Y(1:4348,:)')
            % Y = find(mean(Y)==max(mean(Y)));
            DF_Y.df=Y;
            DF_Y.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);
            DF_Y.ax.(mdlObj.predictor.targetVar)=key.label';                        
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
            G = STAT_test.(mdlObj.targetVar); % get target groupings
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

        function inspectGeometry(mdlObj, nexObj)
            % attach to state-space obj and visualize state-outputs
            % use mask-selection panel to visualize dropout of specific dim
            % combinations in latent space
        end

    end
end