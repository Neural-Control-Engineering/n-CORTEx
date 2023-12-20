function [categorical_outcome, was_target, dprime, reaction_times] = sessionAnalysis(logsout, stage, tbounds)
    trialNum = logsout.getElement('trialNum').Values.Data;
    wasTarget = logsout.getElement('was_target').Values.Data;
    rewardTrigger = logsout.getElement('reward_trigger').Values.Data;
    numLicks = logsout.getElement('numLicks').Values.Data;
    leftTrigger = logsout.getElement('left_trigger').Values.Data;
    rightTrigger = logsout.getElement('right_trigger').Values.Data;
    lickDetector = logsout.getElement('lick_detector').Values.Data;
    time = logsout.getElement('lick_detector').Values.Time;
    if ~isempty(tbounds)
        trialNum = trialNum(time >= tbounds(1) & time <= tbounds(2));
        wasTarget = wasTarget(time >= tbounds(1) & time <= tbounds(2));
        rewardTrigger = rewardTrigger(time >= tbounds(1) & time <= tbounds(2));
        numLicks = numLicks(time >= tbounds(1) & time <= tbounds(2));
        leftTrigger = leftTrigger(time >= tbounds(1) & time <= tbounds(2));
        rightTrigger = rightTrigger(time >= tbounds(1) & time <= tbounds(2));
        lickDetector = lickDetector(time >= tbounds(1) & time <= tbounds(2));
        time = time(time >= tbounds(1) & time <= tbounds(2));
    end
    % get inds for the start of each trial
    trial_starts = find(trialNum == 1);
    trial_ends = zeros(length(trial_starts),1);
    categorical_outcome = cell(length(trial_starts),1);
    was_target = zeros(length(trial_starts),1);
    hit_count = 0;
    target_count = 0;
    fa_count = 0;
    distractor_count = 0;
    reaction_times = [];
    lick_raster = figure('Position', [1220, 1389, 1056, 449]);
    tl = tiledlayout(1,2);
    axs(1) = nexttile; hold on;
    axs(2) = nexttile; hold on;
    t = linspace(-3,5,8001);
    for i = 1:length(trial_starts)
        % get end of each trial
        if i == length(trial_starts)
            trial_ends(i) = max(trialNum);
        else
            trial_ends(i) = trial_starts(i+1)-1;
        end
        % was stimulus target or distractor
        if sum(wasTarget(trial_starts(i):trial_ends(i)))
            was_target(i) = 1;
            target_count = target_count + 1;
        else
            distractor_count = distractor_count + 1;
        end
        % determine stimulus time 
        stim_ind = find(rightTrigger(trial_starts(i):trial_ends(i))==1);
        if isempty(stim_ind)
            stim_ind = find(leftTrigger(trial_starts(i):trial_ends(i))==1);
        end
        stim_ind = stim_ind + trial_starts(i);
        % determine outcome 
        if was_target(i) && sum(rewardTrigger(trial_starts(i):trial_ends(i)))
            % Hit
            %sprintf('Trial %i target: correct', i)
            categorical_outcome{i} = 'Hit';
            hit_count = hit_count + 1;
            try
                lick_inds = find(lickDetector(stim_ind-3000:stim_ind+5000)==1);
            catch
                lick_inds = find(lickDetector(stim_ind-3000:end)==1);
            end
            lick_inds = lick_inds - 150;
            lick_inds = lick_inds(lick_inds > 1);
            if isempty(lick_inds)
                keyboard
            end
            try
                react_inds = find(lickDetector(stim_ind:stim_ind+5000)==1);
            catch
                react_inds = find(lickDetector(stim_ind:end)==1);
            end
            react_inds = react_inds - 150;
            reaction_times = [reaction_times; t(react_inds(1)+3000)];
            % subplot(1,2,1)
            % hold on
            % if hit_count == 19
            %     keyboard
            % end
            axes(axs(1))
            plot(t(lick_inds), repmat(hit_count,length(lick_inds),1), 'k|')
        elseif was_target(i)
            % Miss
            %sprintf('Trial %i target: incorrect', i)
            categorical_outcome{i} = 'Miss';
        elseif sum(lickDetector(stim_ind:stim_ind+1650)) % need to distinguish correct rejection from false alarm
            % False Alarm
            %sprintf('Trial %i distractor: incorrect', i)
            categorical_outcome{i} = 'FA';
            fa_count = fa_count + 1;
            lick_inds = find(lickDetector(stim_ind-3000:stim_ind+5000)==1);
            % subplot(1,2,2)
            % hold on
            axes(axs(2))
            plot(t(lick_inds), repmat(fa_count, length(lick_inds),1), 'k|')
        else
            % Correct Rejection
            %sprintf('Trial %i distractor: correct', i)
            categorical_outcome{i} = 'CR';
        end
    end
    sprintf('Hit rate: %.3f', hit_count/target_count)
    sprintf('False alarm rate: %.3f', fa_count/distractor_count)
    dprime = norminv(hit_count/target_count) - norminv(fa_count/distractor_count);
    sprintf('d'' = %.2f', dprime)
    title(tl, sprintf('d'' = %.2f', dprime), 'FontSize', 16)
    set(lick_raster, 'Visible', 'on')
    axes(axs(1))
    xlim([-3,5])
    title('Hit', 'FontSize', 16, 'FontWeight','normal')
    axes(axs(2))
    title('False Alarm', 'FontSize', 16, 'FontWeight','normal')
    xlim([-3,5])
    ylabel(tl, 'Trial #', 'FontSize', 16)
    xlabel(tl, 'Time (s)', 'FontSize', 16)

    figure()
    histogram(reaction_times, 7, 'FaceColor', 'k', 'EdgeColor', 'k', 'Normalization', 'probability')
    xlabel('Reaction Time (s)', 'FontSize', 16)
    ylabel('Proportion of trials', 'FontSize', 16)
    sprintf('Mean reaction time: %.2f', mean(reaction_times))
end