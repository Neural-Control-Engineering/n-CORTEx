function [curve, fit] = extractCalibration(logsout)
    % get signal and setpoint
    signal = get(logsout,"signalAvg");
    setPoint = get(logsout,"setPoint_out");    
    % isolate acuired signal    
    calibrationMask = (setPoint.Values.Data~=-1);
    signalVals = signal.Values.Data(calibrationMask);
    setPointVals = setPoint.Values.Data(calibrationMask);
    % build LUT
    figure; scatter(signalVals,setPointVals);
    fit = polyfit(signalVals,setPointVals,1);
    curve = [signalVals,setPointVals];
    refline(fit(1),fit(2));
end