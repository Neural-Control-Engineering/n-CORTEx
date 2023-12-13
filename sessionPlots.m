trialNum = logsout.getElement('trialNum').Values.Data;
wasTarget = logsout.getElement('was_target').Values.Data;
rewardTrigger = logsout.getElement('reward_trigger').Values.Data;
numLicks = logsout.getElement('numLicks').Values.Data;
leftTrigger = logsout.getElement('left_trigger').Values.Data;
rightTrigger = logsout.getElement('right_trigger').Values.Data;
lickDetector = logsout.getElement('lick_detector').Values.Data;
filteredLicks = logsout.getElement('filtered_lickometer').Values.Data;
time = logsout.getElement('lick_detector').Values.Time;

figure()
tl = tiledlayout(5,1);
axs = zeros(5,1);
for i = 1:5
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
plot(time, filteredLicks)
title('Analog Lick Signal')
axes(axs(5))
plot(time, lickDetector)
title('Digital Lick Signal')
xlabel('Time (s)')

linkaxes(axs, 'x')

