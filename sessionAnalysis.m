function [categorical_outcome, was_target, dprime] = sessionAnalysis(logsout, stage)
    trialNum = logsout.getElement('trialNum').Values.Data;
    wasTarget = logsout.getElement('was_target').Values.Data;
    rewardTrigger = logsout.getElement('reward_trigger').Values.Data;
    numLicks = logsout.getElement('numLicks').Values.Data;
    leftTrigger = logsout.getElement('left_trigger').Values.Data;
    rightTrigger = logsout.getElement('right_trigger').Values.Data;
    lickDetector = logsout.getElement('lick_detector').Values.Data;
    % get inds for the start of each trial
    trial_starts = find(trialNum == 1);
    trial_ends = zeros(length(trial_starts),1);
    categorical_outcome = cell(length(trial_starts),1);
    was_target = zeros(length(trial_starts),1);
    hit_count = 0;
    target_count = 0;
    fa_count = 0;
    distractor_count = 0;
    lick_raster = figure();
    t = linspace(-3,5,8000);
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
            lick_inds = find(lickDetector(stim_ind-3000:stim_ind+5000)==1);
            if isempty(lick_inds)
                keyboard
            end
            subplot(1,2,1)
            hold on
            % if hit_count == 19
            %     keyboard
            % end
            plot(t(lick_inds), repmat(hit_count,length(lick_inds),1), 'k|')
        elseif was_target(i)
            % Miss
            %sprintf('Trial %i target: incorrect', i)
            categorical_outcome{i} = 'Miss';
        elseif sum(lickDetector(stim_ind:trial_ends(i))) % need to distinguish correct rejection from false alarm
            % False Alarm
            %sprintf('Trial %i distractor: incorrect', i)
            categorical_outcome{i} = 'FA';
            fa_count = fa_count + 1;
            lick_inds = find(lickDetector(stim_ind-3000:stim_ind+5000)==1);
            subplot(1,2,2)
            hold on
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
    sprintf('d-prime = %.2f', dprime)
end