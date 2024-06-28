% Create a configuration object for code generation
cfg = coder.config('mex');
cfg.TargetLang = 'C++';

% Specify the entry-point function and input types
codegen -config cfg extractRT_STFT_mex -args {coder.typeof(double(0), [inf, 767])}
