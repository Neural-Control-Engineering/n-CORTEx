function [fit, specs] = psd2fooof(opts, f, psd)
    % configure fitting method
    if isempty(opts)
        opts = struct;        
    end
    opts.ftCfg_fooof.freqAnalysisMethod="preFFT";        
    if ~isfield(opts,'ftCfg_fooof'); opts.ftCfg_fooof = struct; end
    if ~isfield(opts.ftCfg_fooof,'method'); opts.ftCfg_fooof.method = 'preFFT'; end
    if ~isfield(opts.ftCfg_fooof,'output'); opts.ftCfg_fooof.output = 'fooof'; end
    if ~isfield(opts.ftCfg_fooof,'export'); opts.ftCfg_fooof.export = 1; end
    % if ~isfield(opts.ftCfg_fooof,'tapsmofrq'); opts.ftCfg_fooof.tapsmofrq= 2.857; end
    if ~isfield(opts.ftCfg_fooof,'tapsmofrq'); opts.ftCfg_fooof.tapsmofrq= 2; end
    if ~isfield(opts.ftCfg_fooof,'foilim'); opts.ftCfg_fooof.foilim= [0.3 50]; end % bandpass 0.3 to 40 Hz
    if ~isfield(opts.ftCfg_fooof,'pad'); opts.ftCfg_fooof.pad= 2; end
    if ~isfield(opts.ftCfg_fooof,"opt"); opts.ftCfg_fooof.opt = setFooofOpt(); end
    if ~isfield(opts.ftCfg_fooof,"freqAnalysisMethod"); opts.ftCfg_fooof.freqAnalysisMethod="preFFT"; end
    % apply fit
    specs = fooof(opts, psd', f');
    specs = specs.fooofparams;
    fit = composeSpecs(f, specs);      
end