classdef mdlObj_lda < mdlObject
    properties  
    end

    methods
        function mdlObj = mdlObj_lda(Parent, Origin, dfID_source, predictorID)            
            if nargin < 4
                predictorID=[];
            end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "lda", dfID_source, predictorID);            
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing'); 
            mdlObj.py.stdScaler = sklearnPreProc.StandardScaler();            
            mdlObj.cfg.fitCfg=nex_generateCfgObj(str2func("nexFit_lda"));
            mdlObj.cfg.dmCfg.format="supervised";
            mdlObj.cfg.statCfg.entryParams.fuseAx=1;
            % network, etc.
        end

        function locateDataset(mdlObj)

        end

        function Y = infer(mdlObj, X)
        end

        function train(mdlObj)
        end

        function formatSample(X, Y)
        end

        function getDesignMatrix(mdlObj)
            
            chanCond = mdlObj.cfg.dmCfg.chanSel;
          
            % pool
            TF = table2struct(mdlObj.STAT);
            ptr = mdlObj.STAT.ptr(1);
            TF_pool = arrayfun(@(DF) nexOp_poolAxes(mdlObj.pMap, DF, ptr), TF);
            % slice (manual)
            [TF_slice, ax_slice] = arrayfun(@(DF) nexOp_sliceDF(DF,"chans",{chanCond}), TF_pool, "UniformOutput",false);
            TF_pool_slice=struct2table(TF_pool);
            TF_pool_slice.df=TF_slice; TF_pool_slice.ax=ax_slice;
            % flatten along higher dimensions
            TF_flat = arrayfun(@(DF) nexOp_viewDF(DF), table2struct(TF_pool_slice), "UniformOutput", false);
            STAT=struct2table(cat(1,TF_flat{:})); % re-pack
            % train/test partition            
            if ~isempty(mdlObj.trainMask)
                STAT_train = STAT(mdlObj.trainMask==1,:);
                STAT_test = STAT(mdlObj.trainMask==0,:);
            else
                STAT_train=STAT;
                STAT_test=[];
            end
            mdlObj.TEST.STAT=STAT_test;
            mdlObj.TRAIN.STAT=STAT_train;            
            % compile design matrix
            dmFcn = str2func(sprintf("stat2dm_%s",mdlObj.cfg.dmCfg.format));
            mdlObj.DM = dmFcn(mdlObj);
            % mdlObj.DM = mdlObj.cfg.dmCfg.fcn(mdlObj, dmArgs);
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
            mdlObj.modelObj.partial_fit(X_py, Y_py);                    
        end

        % function DF_Y = predict(mdlObj, DF_X)
        %     % propagate transformation from input layer 
        %     Parent=mdlObj.Parent; parentClass=class(Parent);
        %     if contains(parentClass,"mdlObj")
        %         DF_X_tf = mdlObj.predictor.Parent.transformInput(DF_X);
        %     else
        %         DF_X_tf=DF_X;
        %     end            % predict transformed input
        %     np = py.importlib.import_module("numpy");
        %     X = DF_X_tf.df;
        %     X_py = np.array(X);
        %     Y_py = mdlObj.predictor.model.predict_proba(X_py);                   
        %     % Y_py = mdlObj.predictor.model.predict(X_py);                    
        %     Y = double(Y_py);
        %     key = mdlObj.predictor.DM.K.(mdlObj.predictor.targetVar);
        %     % logit_pt = log(Y./ (1 - Y));     % convert probabilities to log-odds
        %     % logit_smoothed = movmean(logit_pt, 50);
        %     % trial_prob = mean(1 ./ (1 + exp(-logit_smoothed)));
        %     % Y_label = double(mdlObj.predictor.model.classes_);
        %     % figure;plot(Y(1:end,:),'DisplayName','Y(1:4348,:)')
        %     % Y = find(mean(Y)==max(mean(Y)));
        %     DF_Y.df=Y;
        %     DF_Y.ax.(mdlObj.domain.D1)=DF_X.ax.(mdlObj.domain.D1);
        %     DF_Y.ax.(mdlObj.predictor.targetVar)=key.label';                        
        % end

        function Z = transform(mdlObj, X)
            np = py.importlib.import_module('numpy');
            X_py = np.ascontiguousarray(np.array(double(X)));            
            Z_py = mdlObj.modelObj.transform(X_py);
            Z = double(np.array(Z_py));
        end
    end
end