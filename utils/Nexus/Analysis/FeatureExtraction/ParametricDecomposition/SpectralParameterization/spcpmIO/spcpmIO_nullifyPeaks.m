function fitParams_pkNull = spcpmIO_nullifyPeaks(fitParams)
    spcpmFields = fieldnames(fitParams);
    fitParams_pkNull = fitParams;
    key_CF="CF";
    key_PW="PW";
    key_BW="BW";
    for i = 1:length(spcpmFields)
        spcpmField = convertCharsToStrings(spcpmFields{i});
        if contains(spcpmField,key_PW)
            fitParams_pkNull.(spcpmField)=0;
        end
    end
end