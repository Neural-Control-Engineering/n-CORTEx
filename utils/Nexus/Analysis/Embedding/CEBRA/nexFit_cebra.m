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
        X      = mdlObj.DM.X;
        Y_cont = mdlObj.DM.Y_cont;
        Y_disc = mdlObj.DM.Y_disc;
        np = py.importlib.import_module("numpy");
        X_py = np.array(X);
        mdlObj.py.stdScaler = mdlObj.py.stdScaler.fit(X_py);
        X_scaled = mdlObj.py.stdScaler.transform(X_py);

        % Route by which of stat2dm_cebra's two label buckets is populated
        % — see its own docstring for why continuous+discrete can't combine
        % in one fit() call (CEBRA 0.5.0 has no single-session loader for
        % that combination). Y_disc must be an INTEGER-dtype numpy array
        % (int64 here) or CEBRA's own dtype check
        % (cebra.helper._is_integer) misclassifies it as continuous —
        % MATLAB double -> np.array() would otherwise land as float64.
        hasCont = ~isempty(Y_cont);
        hasDisc = ~isempty(Y_disc);
        if hasCont && hasDisc
            error(['[nexFit_cebra] domain.TGT mixes continuous and discrete ' ...
                   'columns -- CEBRA cannot train on both a continuous and a ' ...
                   'discrete index in a single fit. Use domain.CTG to combo-' ...
                   'split by the discrete column(s), and keep domain.TGT ' ...
                   'continuous-only within each combo.']);
        elseif hasCont
            mdlObj.model = mdlObj.model.fit(X_scaled, np.array(Y_cont));
        elseif hasDisc
            mdlObj.model = mdlObj.model.fit(X_scaled, np.array(int64(Y_disc)));
        else
            mdlObj.model = mdlObj.model.fit(X_scaled);
        end
end
