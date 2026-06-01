function fit = kernel_specparam_segmented_multiexp(ax, args)

    % CFG HEADER
    OFF  = args.OFF;   % default = 10
    EXP1 = args.EXP1;  % default = 2   
    EXP2 = args.EXP2;  % default = 12    
    EXP3 = args.EXP3;  % default = 25    
    FC1 = args.FC1; % default = 7
    FC2 = args.FC2; % default = 63
    FC3 = args.FC3; % default = 250


    % CF1  = args.CF1;   % default = 37
    % PW1  = args.PW1;   % default = 45
    % BW1  = args.BW1;   % default = 52    
    % CF2  = args.CF2;   % default = 59
    % PW2  = args.PW2;   % default = 64
    % BW2  = args.BW2;   % default = 70    
    % CF3  = args.CF3;   % default = 78
    % PW3  = args.PW3;   % default = 86
    % BW3  = args.BW3;   % default = 92    
    % CF4  = args.CF4;   % default = 99
    % PW4  = args.PW4;   % default = 106
    % BW4  = args.BW4;   % default = 113    
    % CF5  = args.CF5;   % default = 121
    % PW5  = args.PW5;   % default = 128
    % BW5  = args.BW5;   % default = 135    
    % CF6  = args.CF6;   % default = 142
    % PW6  = args.PW6;   % default = 150
    % BW6  = args.BW6;   % default = 158    
    % CF7  = args.CF7;   % default = 165
    % PW7  = args.PW7;   % default = 172
    % BW7  = args.BW7;   % default = 180    
    % CF8  = args.CF8;   % default = 188
    % PW8  = args.PW8;   % default = 195
    % BW8  = args.BW8;   % default = 202    
    % CF9  = args.CF9;   % default = 210
    % PW9  = args.PW9;   % default = 218
    % BW9  = args.BW9;   % default = 225    
    % CF10 = args.CF10;  % default = 233
    % PW10 = args.PW10;  % default = 240
    % BW10 = args.BW10;  % default = 248

    % === MODEL FORM ===
    f_spec = ax.f;
    % APERIODIC COMPONENT
    % fit_AP = -log10(1+i*f_spec.^EXP1) ...
    %        - log10(1+i*f_spec.^EXP2) ...
    %        - log10(1+i*f_spec.^EXP3);

    % fit_AP = -log10(1+(i*f_spec)./EXP1).^0.9 ...
    %        - log10(1+(i*f_spec)./EXP2).^1.2 ...
    %        - log10((1+(i*f_spec)./EXP3).^6.3);

    fit_AP = -log10((1+(1i*f_spec)./FC1).^EXP1) ...
           - log10((1+(1i*f_spec)./FC2).^(EXP2)) ...
           - log10((1+(1i*f_spec)./FC3).^EXP3);

    % fit_AP = -log10((1+(1i*f_spec)./FC1).^0) ...
    %        - log10((1+(1i*f_spec)./FC2).^EXP2) ...
    %        - log10((1+(1i*f_spec)./FC3).^EXP3);

    % 'WORKS'
     % fit_AP = -log10(1+(i*f_spec)./1).^0 ... 
     %   - log10((1+(i*f_spec)./FC2).^EXP2);
    

     % 
     % fit_AP = -log10(1+(i*f_spec)./1).^0 ...
     %       - log10(1+(i*f_spec)./FC1).^EXP1 ...
     %       - log10((1+(i*f_spec)./FC2).^EXP2);
    
    % PERIODIC COMPONENTS (Gaussian Peaks)
    % infer number of peaks
    cfFields = fieldnames(args);
    cfFields = cfFields(contains(cfFields,'CF'));
    numCF =(regexp(cfFields,'\d+','match'));
    numCF = cellfun(@(cf) str2double(cf), numCF, "UniformOutput", true);
    % fit = 10*log10(abs(10.^(fit_AP+OFF)));
    % fit = abs(OFF + fit_AP);
    fit_PE = zeros(1,length(f_spec));
    % fit = fit_AP;
    for j=numCF'

        CFID = sprintf("CF%d",j);
        PWID = sprintf("PW%d",j);
        BWID = sprintf("BW%d",j);

        CF = args.(CFID);
        PW = args.(PWID);
        BW = args.(BWID);

        fit_PE  = fit_PE + PW  * exp(-(f_spec - CF ).^2 / (2 * BW^2));
        % fit_PE  = fit_PE + BW  * exp(-(f_spec - CF ).^2 / (2 * PW^2));
        % fit = fit + (fit_PE);
    end

    % figure; loglog(f_spec, 10*log10(fit_PE))
    % fit = 10*log10(abs(10.^(fit_AP+OFF))) + 10*log10(fit_PE);
    fit_AP_log = 10*log10(abs(10.^(fit_AP+OFF)));
    % fit_PE_log = 10*log10(fit_PE);
    % figure; loglog(fit_AP_log);
    % figure; loglog(fit_PE);
    % fit = 10*log10(abs(10.^(fit_AP+OFF))) + 10*log10(fit_PE);
    fit = fit_AP_log + 10*(fit_PE);
    % figure; loglog(f_spec, fit);
    % PERIODIC COMPONENTS (Gaussian peaks)
    % fit_PE1  = PW1  * exp(-(f_spec - CF1 ).^2 / (2 * BW1^2));
    % fit_PE2  = PW2  * exp(-(f_spec - CF2 ).^2 / (2 * BW2^2));
    % fit_PE3  = PW3  * exp(-(f_spec - CF3 ).^2 / (2 * BW3^2));
    % fit_PE4  = PW4  * exp(-(f_spec - CF4 ).^2 / (2 * BW4^2));
    % fit_PE5  = PW5  * exp(-(f_spec - CF5 ).^2 / (2 * BW5^2));
    % fit_PE6  = PW6  * exp(-(f_spec - CF6 ).^2 / (2 * BW6^2));
    % fit_PE7  = PW7  * exp(-(f_spec - CF7 ).^2 / (2 * BW7^2));
    % fit_PE8  = PW8  * exp(-(f_spec - CF8 ).^2 / (2 * BW8^2));
    % fit_PE9  = PW9  * exp(-(f_spec - CF9 ).^2 / (2 * BW9^2));
    % fit_PE10 = PW10 * exp(-(f_spec - CF10).^2 / (2 * BW10^2));
    
    % COMBINE ALL COMPONENTS
    % fit = fit_AP + fit_PE1 + fit_PE2 + fit_PE3 + fit_PE4 + fit_PE5 + ...
    %             fit_PE6 + fit_PE7 + fit_PE8 + fit_PE9 + fit_PE10 + OFF;

    % fit = fit_AP + OFF;
    % fit = fit + OFF;
end