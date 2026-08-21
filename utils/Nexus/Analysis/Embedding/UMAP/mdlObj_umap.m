classdef mdlObj_umap < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_umap(Parent, Origin, dfID_source)
            if isempty(dfID_source)
                dfID_source = Parent.dfID_source;
            end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "umap", dfID_source);
            mdlObj.py.np = py.importlib.import_module('numpy');
            sklearnPreProc = py.importlib.import_module('sklearn.preprocessing');
            mdlObj.Scaler.model = sklearnPreProc.StandardScaler();
            mdlObj.cfg.fitCfg = nex_generateCfgObj(str2func("nexFit_umap"));
            isHeadless = isfield(mdlObj.nexon, 'settings') && ...
                         isfield(mdlObj.nexon.settings, 'headless') && ...
                         mdlObj.nexon.settings.headless;
            if isHeadless
                mdlObj.setupDomain();
            end
        end

        function setupDomain(mdlObj)
            if isfield(mdlObj.domain, 'D2') && numel(mdlObj.domain.D2) >= 1
                mdlObj.domain.FTR = mdlObj.domain.D2(1);
            end
            mdlObj.initDomainBus();
        end

        function DF_Z = transform(mdlObj, DF_X)
            disp("transforming umap...");
            if isempty(DF_X.df)
                DF_Z = [];
                return;
            end
            X_flat   = mdlObj.flattenInput(DF_X);   % nexHR_transform or reshape → 2D
            X_py     = mdlObj.py.np.atleast_2d(mdlObj.py.np.array(X_flat));
            X_scaled = mdlObj.Scaler.model.transform(X_py);
            if isstruct(mdlObj.Reducer) && isfield(mdlObj.Reducer, 'model') && ...
                    ~isempty(mdlObj.Reducer.model)
                X_scaled = mdlObj.Reducer.model.transform(X_scaled);
            end
            Z_py = mdlObj.model.transform(X_scaled);
            Z    = double(Z_py);
            DF_Z.df        = Z;
            D1             = char(mdlObj.domain.D1);
            if D1 ~= "None"
                DF_Z.ax.(D1) = DF_X.ax.(D1);
            end
            DF_Z.ax.latent = 1:size(Z, 2);
            DF_Z           = nex_initAxisPointer_v2(DF_Z);
        end

        function saveFit(mdlObj, uniqueID)
            [h5Dir, ~, ~] = fileparts(char(mdlObj.nexon.console.BASE.DTS.h5_path(1)));
            fitDir = fullfile(h5Dir, sprintf('mdlObj_umap_%s', uniqueID));
            if ~exist(fitDir, 'dir'), mkdir(fitDir); end
            mdlObj.fitPath = fitDir;
            pickle = py.importlib.import_module('pickle');
            fid = py.open(fullfile(fitDir, 'model.pkl'), 'wb');
            pickle.dump(mdlObj.model, fid); fid.close();
            fid = py.open(fullfile(fitDir, 'scaler.pkl'), 'wb');
            pickle.dump(mdlObj.Scaler.model, fid); fid.close();
            if isstruct(mdlObj.Reducer) && isfield(mdlObj.Reducer, 'model') && ...
                    ~isempty(mdlObj.Reducer.model)
                fid = py.open(fullfile(fitDir, 'reducer.pkl'), 'wb');
                pickle.dump(mdlObj.Reducer.model, fid); fid.close();
            end
        end

        function loadFit(mdlObj, fitDir)
            mdlObj.fitPath = fitDir;
            pickle    = py.importlib.import_module('pickle');
            fid       = py.open(fullfile(fitDir, 'model.pkl'), 'rb');
            mdlObj.model = pickle.load(fid); fid.close();
            fid       = py.open(fullfile(fitDir, 'scaler.pkl'), 'rb');
            mdlObj.Scaler.model = pickle.load(fid); fid.close();
            reducerPath = fullfile(fitDir, 'reducer.pkl');
            if exist(reducerPath, 'file')
                if isempty(mdlObj.Reducer), mdlObj.Reducer = struct(); end
                fid = py.open(reducerPath, 'rb');
                mdlObj.Reducer.model = pickle.load(fid); fid.close();
            end
        end
    end
end
