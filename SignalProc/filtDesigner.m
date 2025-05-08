function [b, a]  = filtDesigner(vis)
    % Bandpass filter design parameters
    low_freq = 0.1;  % Lower cutoff frequency in Hz
    % high_freq = 5;  % Upper cutoff frequency in Hz
    scaleFactor = 1;
    high_freq = 100;
    sampling_rate = 1000;  % Sampling rate in Hz
    % filter_order = 100;  % Filter order (an even number for linear phase)
    filter_order =25;
    
    % Normalize frequencies
    normalized_low_freq = low_freq / (0.5 * sampling_rate);
    normalized_high_freq = high_freq / (0.5 * sampling_rate);
    
    % Design the bandpass filter
    b = scaleFactor*fir1(filter_order, [normalized_low_freq, normalized_high_freq], 'bandpass');
    a = 1;

    % convert to minimum phase
    % b_min = firminphase(b);

    [groupDelay, ~] = grpdelay(b, a, [], sampling_rate);    
    
    % Visual 1
    if vis
        figure
        % Plot the frequency response of the filter
        freqz(b, 1, 1024, sampling_rate);
    end

    % Visual 2
    fvtool(b, 1, b_min, 1)
    legend('Linear-Phase', 'Minimum-Phase')
        
    % RLC CIRCUIT
    % R1 = 890;
    % R2 = 890 * 4;
    % C1 = 10e-6;
    % C2 = 10e-6;
    % num0 = 0;
    % num1 = 2*pi()*-R2*C1;
    % den0 = 1;
    % den1 = 2*pi()*R1*(C1+C2);
    % den2 = (2*pi())*(2*pi())*R1*R2*C1*C2;
    % b_circ = [num1, num0];
    % a_circ = [den2, den1,den0];
    % figure
    % freqz(b_circ, a_circ, 1024, sampling_rate);

    % IIR OPTION
    Fs = 1000; % Sampling frequency in Hz
    Fpass = 0.2; % Passband frequency in Hz
    Fstop = 0.05; % Stopband frequency in Hz
    Apass = 1; % Passband ripple in dB
    Astop = 60; % Stopband attenuation in dB
    
    % Design Butterworth high-pass IIR filter
    d = designfilt('highpassiir', ...
        'StopbandFrequency', Fstop, 'PassbandFrequency', Fpass, ...
        'StopbandAttenuation', Astop, 'PassbandRipple', Apass, ...
        'SampleRate', Fs);
     
    d = fdesign.highpass('Fst,Fp,Ast,Ap',0.1,0.5,40,1,1000);
    d = design(d,'butter');
    [b,a ] = tf(d);

    fvtool(d) % Visualize filter response

    roots(a);
end