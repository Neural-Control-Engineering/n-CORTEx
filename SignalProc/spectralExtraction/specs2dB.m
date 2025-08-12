function specsdB = specs2dB(specs, scalingFactor)
    aperiodicParams = specs.aperiodic_params;
    peakParams = specs.peak_params;
    % apply 20*log10 to offset
    aperiodicParams(1) = 20*log10(aperiodicParams(1)/scalingFactor);
    % apply 20*log10 to PW
    peakParams(:,2) = 20*log10(peakParams(:,2)./scalingFactor);
    specsdB = specs;
    specsdB.peak_params = peakParams;
    specsdB.aperiodic_params = aperiodicParams;

   
end