function DF_out = nexFit_cebra(mdlObj, args)

        % CFG HEADER   
       batch_size = args.batch_size; % default = 512
       learning_rate = args.learning_rate; % default = 1e-4   
       temperature = args.temperature; % default = 0.05
       max_iterations = args.max_iterations; % default = 1000
       max_adapt_iterations = args.max_adapt_iterations; % default = 10
       time_offsets = args.time_offsets; % default = 50
       output_dimension = args.output_dimension; % default = 8

       disp("fitting cebra...");
       % temporary indexing    
        % chanCond = [1:10];
        % X = mdlObj.DM.X(:,chanCond);        
        X = mdlObj.DM.X;        
        Y = mdlObj.DM.Y;
        % DM_py = np.array(mdlObj.DM);
        np = py.importlib.import_module("numpy");
        X_py = np.array(X);
        Y_py = np.array(Y);
        mdlObj.py.stdScaler = mdlObj.py.stdScaler.fit(X_py);
        X_scaled = mdlObj.py.stdScaler.transform(X_py);
        mdlObj.model = mdlObj.model.fit(X_scaled, Y_py);        
end