classdef mdlObj_linear < mdlObject

    properties
    end

    methods
        function mdlObj = mdlObj_linear(Parent, Origin, dfID_source, headline)
            if nargin < 4, headline = []; end
            mdlObj = mdlObj@mdlObject(Parent, Origin, "linear", dfID_source, [], headline);
            mdlObj.py.np = py.importlib.import_module('numpy');
            mdlObj.cfg.fitCfg  = nex_generateCfgObj(str2func("nexFit_linear"));
            mdlObj.cfg.dmCfg.format = "regression";
        end

        function Y_pred = predict(mdlObj, X)
            np    = mdlObj.py.np;
            X_py  = np.array(double(X));
            Y_py  = mdlObj.model.predict(X_py);
            Y_pred = double(np.array(Y_py));
        end

        function storeResult(mdlObj, resultID, data)
            mdlObj.RESULTS.(resultID) = data;
            mdlObj.refreshSRC();
        end

        function refreshSRC(mdlObj)
            if isfield(mdlObj.Figure, 'srcDropdown') && isvalid(mdlObj.Figure.srcDropdown)
                keys = fieldnames(mdlObj.RESULTS);
                if isempty(keys), return; end
                mdlObj.Figure.srcDropdown.Items = keys;
                if ~ismember(mdlObj.Figure.srcDropdown.Value, keys)
                    mdlObj.Figure.srcDropdown.Value = keys{1};
                end
                nexFigure_linear_renderSRC(mdlObj);
            end
        end
    end
end
