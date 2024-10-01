function specs_perturb =  perturbSpecs(dash, f, noise, shakeFactor, specs)
    aperiodic_params = specs.aperiodic_params;
    peak_params = specs.peak_params;    
    noise_sc = rand() * 1.5;
    shake = rand() * shakeFactor;
    
    for i = 1:size(peak_params,1)
        opSide = ceil(rand()*2);
        switch opSide
            case 1
                peak_params(i,:) = peak_params(i,:) + peak_params(i,:).*shakeFactor;
            case 2
                peak_params(i,:) = peak_params(i,:) - peak_params(i,:).*shakeFactor;
        end        
    end

    for i = 1:size(aperiodic_params,2)
        opSide = ceil(rand()*2);
        if i == 2 % if this is the exp param use a different 'shakeFactor'                        
            shake = rand()*0.06;                   
        end
        switch opSide
            case 1
                aperiodic_params(i) = aperiodic_params(i) + aperiodic_params(i) * shake;
            case 2
                aperiodic_params(i) = aperiodic_params(i) - aperiodic_params(i) * shake;
        end        
    end
    sp.aperiodic_params = aperiodic_params;
    sp.peak_params = peak_params;
    fit = composeSpecs(f, sp);    
    psd_perturb = noise * noise_sc + fit;
    % updateSpecsDash(dash, f, psd_perturb, fit);    
    specs_perturb = formatSpec(f, sp, psd_perturb, []);
end