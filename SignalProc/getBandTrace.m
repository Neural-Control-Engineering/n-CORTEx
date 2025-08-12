function bandTrace = getBandTrace(b, psd, band, freqResponse)
    bandTrace = psd(:,find(strcmp(band,b)==1),:);
    switch freqResponse
        case "mag"
            bandTrace = 10*log10(abs(bandTrace));
        case "phase"
            bandTrace = angle((bandTrace));
    end
end