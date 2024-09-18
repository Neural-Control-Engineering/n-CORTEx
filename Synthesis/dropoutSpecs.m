function specs_dropout = dropoutSpecs(dash, f, noise, specs)    
    peak_params = specs.peak_params;
    aperiodic_params = specs.aperiodic_params;
    specs_dropout = {};
    for i = 1:size(peak_params,1)
        antiIdx = ones(size(peak_params,1),1);
        antiIdx(i) = 0;
        peak_params_drop = peak_params((antiIdx)==1,:);
        sp.aperiodic_params = aperiodic_params;
        sp.peak_params = peak_params_drop;
        fit = composeSpecs(f, sp);
        psd_drop = fit + noise;
        sp_dropout = formatSpec(f, sp, psd_drop,[]);
        specs_dropout = [specs_dropout; sp_dropout];
        % updateSpecsDash(dash, f, psd_drop, fit);    
    end
end