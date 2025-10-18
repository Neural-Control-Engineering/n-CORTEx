function psd = spec2psd(f_spec, spec, aperiodic_mode, periodic_mode)
    % fit with offset, exponent, and knee parameter
    OFF = spec(1);
    % EXP = spec(2);
    % if knee
    %     KNE = spec(3);
    %     peakStart = 4;
    % else
    %     KNE = 0;
    %     peakStart = 3;
    % end
    switch aperiodic_mode
        case 'fixed'
            EXP = spec(2);
            psd_AP = log10(f_spec.^EXP);
            PE_start = 3;
        case 'knee'
            EXP = spec(2);
            KNE = spec(3);           
            psd_AP = log10(KNE + f_spec.^EXP);
            PE_start = 4;
        case 'doublexp'
            EXP0 = spec(2);
            KNE = spec(3);
            EXP1 = spec(4);
            psd_AP = log10(KNE + f_spec.^EXP0) + log10(f_spec.^EXP1);
            % psd_AP = -log10(f_spec.^EXP0) - log10(KNE+f_spec.^EXP1);
            PE_start = 5;
    end
    % KNE=0;
    % psd = 10*log10(1./(f_spec.^(EXP)));
    % psd = log10(1./(f_spec.^(EXP)));
    psd = OFF - psd_AP;
    % psd = (1./(f_spec.^(EXP)));
    switch periodic_mode
        case 'gaussian'
            for i = PE_start:3:size(spec,2)
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
        case 'skewed_gaussian'
            for i = PE_start:4:size(spec,2)
                peak = spec(i:i+2);
                mu = peak(1);
                sigma = peak(3);
                A = peak(2);
                skew = peak(4);
                % A = log10(peak(3));
                G = A * exp(-(f_spec - mu).^2 / (2 * sigma^2));
                psd = psd+(G);
            end
            % psd = psd+OFF;
            % psd = psd+10*log10(OFF);
    end
end

% delete(findall(nexon.console.NPXLS.shanks.shank1.scope.channelGram1.Figure.panel1.ph.Parent,'Type','datatip'));
