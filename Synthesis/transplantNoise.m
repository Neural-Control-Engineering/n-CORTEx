function synthPSD = transplantNoise(f, synthPSD, T_valid, F)
    % select random row from T_valid
    rIdx = ceil((rand() * height(T_valid)));
    valRow = T_valid(rIdx,:);
    valFooof = valRow.fooofparams{1};
    valPSD = valFooof.power_spectrum;    
    sampleLabel = valRow.sampleLabel;    
    psd_sample = valFooof.power_spectrum;
    sampleLabel  = valRow.sampleLabel;
    pmt_sample = grabPMT(sampleLabel, F);
    psd_comp = composeSpecs(f, valFooof);
    psd_noise = psd_sample - psd_comp;
    pmt_noise = pmt_sample - psd_comp;
    noise_sc = rand();
    noise_type = ceil(rand()*2);
    switch noise_type
        case 1
            synthPSD = synthPSD + psd_noise * noise_sc;
        case 2
            synthPSD = synthPSD + pmt_noise * noise_sc;
    end    
end