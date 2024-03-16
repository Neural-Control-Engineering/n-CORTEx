function signalOut = linearPhaseBP(params, signalIn, fs, fPass, order)    
    % Design the bandpass filter with linear phase response
    b = fir1(order, fPass/(fs/2), 'BANDPASS');
    
    % Display the frequency response of the filter
    freqz(b, 1, fs, fs);
    
    % Apply the filter to your signal (replace 'yourSignal' with your actual signal)
    signalOut = filter(b, 1, signalIn);
end