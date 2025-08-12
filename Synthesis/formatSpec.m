function specForm = formatSpec(f, sp, psd, args)
    specForm.aperiodic_params = sp.aperiodic_params;
    specForm.peak_params = sp.peak_params;
    specForm.peak_types = "gaussian";
    specForm.power_spectrum = psd;
    specForm.freq = f;
end