function fit = kernel_specparam_skewed_multiexp(ax, args)

    % CFG HEADER
    OFF  = args.OFF;   % default = 10
    EXP1 = args.EXP1;  % default = 2
    KNE1 = args.KNE1;  % default = 5    
    EXP2 = args.EXP2;  % default = 12
    KNE2 = args.KNE2;  % default = 18
    EXP3 = args.EXP3;  % default = 25
    KNE3 = args.KNE3;  % default = 31    
    CF1  = args.CF1;   % default = 37
    PW1  = args.PW1;   % default = 45
    BW1  = args.BW1;   % default = 52    
    CF2  = args.CF2;   % default = 59
    PW2  = args.PW2;   % default = 64
    BW2  = args.BW2;   % default = 70    
    CF3  = args.CF3;   % default = 78
    PW3  = args.PW3;   % default = 86
    BW3  = args.BW3;   % default = 92    
    CF4  = args.CF4;   % default = 99
    PW4  = args.PW4;   % default = 106
    BW4  = args.BW4;   % default = 113    
    CF5  = args.CF5;   % default = 121
    PW5  = args.PW5;   % default = 128
    BW5  = args.BW5;   % default = 135    
    CF6  = args.CF6;   % default = 142
    PW6  = args.PW6;   % default = 150
    BW6  = args.BW6;   % default = 158    
    CF7  = args.CF7;   % default = 165
    PW7  = args.PW7;   % default = 172
    BW7  = args.BW7;   % default = 180    
    CF8  = args.CF8;   % default = 188
    PW8  = args.PW8;   % default = 195
    BW8  = args.BW8;   % default = 202    
    CF9  = args.CF9;   % default = 210
    PW9  = args.PW9;   % default = 218
    BW9  = args.BW9;   % default = 225    
    CF10 = args.CF10;  % default = 233
    PW10 = args.PW10;  % default = 240
    BW10 = args.BW10;  % default = 248

    % === MODEL FORM ===
    f_spec = ax.f;
    % APERIODIC COMPONENT
    fit_AP = -log10(KNE1 + f_spec.^EXP1) ...
           - log10(KNE2 + f_spec.^EXP2) ...
           - log10(KNE3 + f_spec.^EXP3);
    
    % PERIODIC COMPONENTS (Gaussian peaks)
    fit_PE1  = PW1  * exp(-(f_spec - CF1 ).^2 / (2 * BW1^2));
    fit_PE2  = PW2  * exp(-(f_spec - CF2 ).^2 / (2 * BW2^2));
    fit_PE3  = PW3  * exp(-(f_spec - CF3 ).^2 / (2 * BW3^2));
    fit_PE4  = PW4  * exp(-(f_spec - CF4 ).^2 / (2 * BW4^2));
    fit_PE5  = PW5  * exp(-(f_spec - CF5 ).^2 / (2 * BW5^2));
    fit_PE6  = PW6  * exp(-(f_spec - CF6 ).^2 / (2 * BW6^2));
    fit_PE7  = PW7  * exp(-(f_spec - CF7 ).^2 / (2 * BW7^2));
    fit_PE8  = PW8  * exp(-(f_spec - CF8 ).^2 / (2 * BW8^2));
    fit_PE9  = PW9  * exp(-(f_spec - CF9 ).^2 / (2 * BW9^2));
    fit_PE10 = PW10 * exp(-(f_spec - CF10).^2 / (2 * BW10^2));
    
    % COMBINE ALL COMPONENTS
    fit = fit_AP + fit_PE1 + fit_PE2 + fit_PE3 + fit_PE4 + fit_PE5 + ...
                fit_PE6 + fit_PE7 + fit_PE8 + fit_PE9 + fit_PE10 + OFF;
end