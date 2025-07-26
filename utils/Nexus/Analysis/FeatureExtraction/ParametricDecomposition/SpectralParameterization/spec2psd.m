function psd = spec2psd(f_spec, spec)
    OFF = spec(1);
    EXP = spec(2);
    % psd = 10*log10(1./(f_spec.^(EXP)));
    psd = log10(1./(f_spec.^(EXP)));
    % psd = (1./(f_spec.^(EXP)));
    for i = 3:3:size(spec,2)
        peak = spec(i:i+2);
        mu = peak(1);
        sigma = peak(3);
        A = peak(2);
        % A = log10(peak(3));
        G = A * exp(-(f_spec - mu).^2 / (2 * sigma^2));
        psd = psd+(G);
    end
    psd = psd+OFF;
    % psd = psd+10*log10(OFF);
end