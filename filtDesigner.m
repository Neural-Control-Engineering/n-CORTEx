% Bandpass filter design parameters
low_freq = 2.0;  % Lower cutoff frequency in Hz
high_freq = 6;  % Upper cutoff frequency in Hz
sampling_rate = 1000;  % Sampling rate in Hz
filter_order = 1000;  % Filter order (an even number for linear phase)

% Normalize frequencies
normalized_low_freq = low_freq / (0.5 * sampling_rate);
normalized_high_freq = high_freq / (0.5 * sampling_rate);

% Design the bandpass filter
b = 3*fir1(filter_order, [normalized_low_freq, normalized_high_freq], 'bandpass');

figure
% Plot the frequency response of the filter
freqz(b, 1, 1024, sampling_rate);

%% RLC CIRCUIT
R1 = 890;
R2 = 890 * 4;
C1 = 10e-6;
C2 = 10e-6;
num0 = 0;
num1 = 2*pi()*-R2*C1;
den0 = 1;
den1 = 2*pi()*R1*(C1+C2);
den2 = (2*pi())*(2*pi())*R1*R2*C1*C2;
b_circ = [num1, num0];
a_circ = [den2, den1,den0];
figure
freqz(b_circ, a_circ, 1024, sampling_rate);