function DF_form = formatSpecs(DF, format, specsMap)
    switch format
        case "timeFrequency"
            DF_form = formatSpec_timeFrequency(DF,specsMap);
        case "parametric"
            DF_form = formatSpec_parametric(DF,specsMap);
    end
end