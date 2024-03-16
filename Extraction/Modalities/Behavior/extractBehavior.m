function behaviorExtract = extractBehavior(params, subject, sessionNames)
    % slrt behavior logs
    switch params.extractCfg.behavior.slrt.experiment
        case "JOLT"
            disp("extracting behavior for JOLT experiment");
            behaviorExtract = extractJOLT(params, subject, sessionNames); 
        case "Craig"
        otherwise
            disp("Behavior not yet implemented");
    end
end