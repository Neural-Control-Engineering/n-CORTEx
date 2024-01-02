trialNum = logsout.getElement('trialNum').Values.Data;
wasTarget = logsout.getElement('was_target').Values.Data;
rewardTrigger = logsout.getElement('reward_trigger').Values.Data;
numLicks = logsout.getElement('numLicks').Values.Data;
leftTrigger = logsout.getElement('left_trigger').Values.Data;
rightTrigger = logsout.getElement('right_trigger').Values.Data;
lickDetector = logsout.getElement('lick_detector').Values.Data;
filteredLicks = logsout.getElement('filtered_lickometer').Values.Data;
raw_licks = logsout.getElement('lickometer_piezo').Values.Data;
ADout = logsout.getElement('ADout').Values.Data;
time = logsout.getElement('lick_detector').Values.Time;

figure()
tl = tiledlayout(7,1);
axs = zeros(7,1);
for i = 1:7
    axs(i) = nexttile;
end

axes(axs(1))
plot(time, leftTrigger)
title('Left Piezo')
axes(axs(2))
plot(time, rightTrigger)
title('Right Piezo')
axes(axs(3))
plot(time, rewardTrigger)
title('Water Reward Trigger')
axes(axs(4))
plot(time, raw_licks)
title('Raw Lick Signal')
axes(axs(5))
plot(time, filteredLicks)
title('Filtered Lick Signal')
axes(axs(6))
plot(time, ADout)
title('Rectified Lick Signal')
axes(axs(7))
plot(time, lickDetector)
title('Digital Lick Signal')
xlabel('Time (s)')

linkaxes(axs, 'x')

