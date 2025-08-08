function psd = spec2psd_legacy(f_spec, spec, knee)
    % fit with offset, exponent, and knee parameter
    OFF = spec(1);
    EXP = spec(2);
    if knee
        KNE = spec(3);
        peakStart = 4;
    else
        KNE = 0;
        peakStart = 3;
    end
    % KNE=0;
    % psd = 10*log10(1./(f_spec.^(EXP)));
    % psd = log10(1./(f_spec.^(EXP)));
    psd = OFF - log10(KNE + f_spec.^EXP);
    % psd = (1./(f_spec.^(EXP)));
    for i = peakStart:3:size(spec,2)
        peak = spec(i:i+2);
        mu = peak(1);
        sigma = peak(3);
        A = peak(2);
        % A = log10(peak(3));
        G = A * exp(-(f_spec - mu).^2 / (2 * sigma^2));
        psd = psd+(G);
    end
    % psd = psd+OFF;
    % psd = psd+10*log10(OFF);
end