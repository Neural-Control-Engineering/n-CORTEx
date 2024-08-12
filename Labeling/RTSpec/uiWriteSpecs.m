function uiWriteSpecs(dash, edt, event)    
    if contains(event.Source.Tag,"spc")
        % recover spec Idx
        specNum = split(event.Source.Tag,"_");
        paramName = string(specNum{2});
        specNum = string(specNum{1});        
        specNum = str2num(strrep(specNum,"spc",""));
        % write value to userData
        oldSpecs = event.Source.Parent.Parent.UserData.specs;
        switch paramName
            case "CF"
                spIdx = 1;
            case "PW"
                spIdx = 2;
            case "BW"
                spIdx = 3;
        end
        event.Source.Parent.Parent.UserData.specs.peak_params(specNum, spIdx) = event.Value;
    elseif strcmp(event.Source.Tag,"Bias") || strcmp(event.Source.Tag,"EXP")
        paramName = event.Source.Tag;
        switch paramName
            case "EXP"
                apIdx = 2;
            case "Bias"
                apIdx = 1;
        end
        event.Source.Parent.Parent.UserData.specs.aperiodic_params(apIdx) = event.Value;
    end
    % updateDash
    uiUpdateSpecs(dash);

end