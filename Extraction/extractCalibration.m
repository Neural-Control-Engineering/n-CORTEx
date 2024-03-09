function [curve, fit] = extractCalibration(logsout)
    signal = get(logsout,"signalAvg");
    force = get(logsout,"tcpRx");
    acqTimes = get(logsout,"S_out");
    
    signalVals = signal.Values.Data;
    forceVals = force.Values.Data;
    acqTimePts = acqTimes.Values.Time; 
    
    actTimePts = (acqTimes.Values.Data~=0) & (forceVals~=1);
    actTimePts = acqTimePts(acqTimes.Values.Data~=0);
    signalVals = signalVals(acqTimes.Values.Data~=0);
    forceVals = forceVals(acqTimes.Values.Data~=0);
    
    figure; scatter(round(signalVals,2),round(double((forceVals)),1))
end