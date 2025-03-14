function specOut = extractSpecParamOutputs(spec, args)
    aperiodic_params = double(spec.aperiodic_params);
    peak_params = double(spec.peak_params);
    specOut.aperiodic_params = aperiodic_params;
    specOut.periodic_params = peak_params;
end