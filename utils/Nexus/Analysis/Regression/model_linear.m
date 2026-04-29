function model = model_linear(args)
% Initialise the sklearn regression model for mdlObj_linear.
% Called at construction by mdlObject via model_<modelID> convention.
% CFG HEADER is parsed to supply defaults when called with no args.

    % CFG HEADER
    model_type = args.model_type; % default = "lasso"
    alpha      = args.alpha;      % default = 0.01
    max_iter   = args.max_iter;   % default = 5000

    mod = py.importlib.import_module('sklearn.linear_model');
    switch char(model_type)
        case 'lasso'
            model = mod.Lasso(pyargs('alpha', alpha, 'max_iter', int32(max_iter)));
        case 'lasso_cv'
            model = mod.LassoCV(pyargs('max_iter', int32(max_iter), 'cv', int32(5)));
        case 'ridge'
            model = mod.Ridge(pyargs('alpha', alpha));
        case 'ridge_cv'
            model = mod.RidgeCV();
        case 'ols'
            model = mod.LinearRegression();
        otherwise
            error('[model_linear] unknown model_type "%s" — use lasso, lasso_cv, ridge, ridge_cv, or ols', model_type);
    end
end
