function params = setCTBGparams(modelName)
    % Define the parameters from Table 2
    params = struct( ...
        'r', 80, ...               % mm
        'sigma_prime', 3.3, ...   % mV
        'phi_N0', 1, ...           % s^-1        
        'gamma_E', 116, ...       % s^-1
        'alpha_E', 45, ...        % s^-1
        'alpha_R', 45, ...        % s^-1
        'alpha_S', 45, ...        % s^-1
        'beta_E', 180, ...        % s^-1
        'beta_R', 180, ...        % s^-1
        'beta_S', 180, ...        % s^-1
        'alpha_B',90, ...          % s^-1
        'beta_B',360, ...         % s^-1
        'tau_RE', 45, ...          % ms
        'tau_SE', 45, ...          % ms
        'tau_ES', 35, ...          % ms
        'tau_BE', 10, ...          % ms        
        'Q_max_E', 300, ...       % s^-1
        'Q_max_S', 300, ...       % s^-1
        'Q_max_R', 300, ...       % s^-1
        'Q_max_B', 200, ...       % s^-1
        'theta_E', 14, ...        % mV
        'theta_B', 14, ...        % mV
        'theta_R', 13, ...        % mV
        'theta_S', 13, ...        % mV
        'nu_EE', 1.6, ...         % mV s
        'nu_EI', -1.9, ...        % mV s
        'nu_ES', 0.4, ...         % mV s
        'nu_RE', 0.15, ...         % mV s
        'nu_RS', 0.03, ...         % mV s
        'nu_BE', 0.08, ...         % mV s        
        'nu_BS', 0.1, ...         % mV s
        'nu_SE', 0.8, ...         % mV s
        'nu_SR', -0.4, ...        % mV s
        'nu_SB', -0.2, ...        % mV s
        'nu_SN', 0.5 ...          % mV s
    );
    % calculated params
    %% STEADY STATES
    params.V_E0=(params.nu_EE+params.nu_EI)*params.phi_E0;
    
    % Export parameters to the Simulink model workspace
    % modelName = 'your_model_name'; % Replace with your Simulink model name
    load_system(modelName); % Load the model if not already loaded
    % Get the model workspace
    modelWorkspace = get_param(modelName, 'ModelWorkspace');
    % Set each parameter as a global variable in the model workspace
    % Loop through th e fields in params
    for field = fieldnames(params)'
        paramName = field{1}; % Get the name of the parameter
        paramValue = params.(paramName); % Get the value of the parameter
        
        % Create a Simulink.Parameter object with ExportedGlobal storage class
        paramObj = Simulink.Parameter(paramValue);
        paramObj.CoderInfo.StorageClass = 'ExportedGlobal';
        
        % Assign the parameter object to the model workspace        
        assignin(modelWorkspace, paramName, paramObj);
    end
    
    % Save the model to retain the changes
    save_system(modelName);

end
    