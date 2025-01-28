function [curve, fit] = extractCalibration(calibData, type)
    switch type
        case 1
            % get signal and setpoint
            signal = get(calibData,"signalAvg");
            setPoint = get(calibData,"setPoint_out");
            % isolate acuired signal
            calibrationMask = (setPoint.Values.Data~=-1);
            signalVals = signal.Values.Data(calibrationMask);
            setPointVals = setPoint.Values.Data(calibrationMask);
            % build LUT
            figure; scatter(signalVals,setPointVals);
            fit = polyfit(signalVals,setPointVals,1);
            curve = [signalVals,setPointVals];
            refline(fit(1),fit(2));
        case 2
            X = calibData.X;
            Y = calibData.Y;
            idx_keep = find(X~=-1);
            X = X(idx_keep);
            Y = Y(idx_keep);
            fit_1 = polyfit(X,Y,1);
            fit_2 = polyfit(X,Y,2);
            fit = {fit_1; fit_2};
            curve = [X, Y];

    end
    
end

% figure; scatter(signalVals,setPointVals);
%     fit = polyfit(signalVals,setPointVals,1);
%     curve = [signalVals,setPointVals];
%     refline(fit(1),fit(2));