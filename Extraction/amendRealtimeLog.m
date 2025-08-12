function amendRealtimeLog(params)
    % fixing realtime log missing field
    rawDir = params.paths.Data.RAW.SLRT.cloud;
    dirItems = dir(rawDir);
    dirTable = struct2table(dirItems);
    fileCond = ~strcmp(dirTable.name,'.') & ~strcmp(dirTable.name,'..');
    sessionLabels = convertCharsToStrings(dirTable.name);    
    sessionsOI = sessionLabels(67:631);
    sessionDates = arrayfun(@(x) parseSessionLabel(x,"date"), sessionsOI, "UniformOutput",true);
    sessionDates = datetime(sessionDates);
    sessionsAfterJan = sessionDates > datetime("27-Jan-2025");
    sessions2amend = sessionsOI(sessionsAfterJan);
    for i = 1:length(sessions2amend)
        session = sessions2amend(i);
        sessionLog = load(fullfile(rawDir,session));
        sessionLog.realtimeLog.session.sense.sense1.calibration.LUT.func=str2func("gompertz");
        % write it back
        realtimeLog = sessionLog.realtimeLog;
        save(fullfile(rawDir,strcat(session)),"realtimeLog");
    end

end