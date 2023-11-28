function sessionAnalysis(logsout, stage)
    trialNum = logsout.getElement('trialNum').Values.Data;
    wasTarget = logsout.getElement('was_target').Values.Data;
    rewardTrigger = logsout.getElement('reward_trigger').Values.Data;
    numLicks = logsout.getElement('numLicks').Values.Data;
    % get inds for the start of each trial
    trial_starts = find(trialNum == 1);
    trial_ends = zeros(length(trial_starts),1);
    for i = 1:length(trial_starts)
        % get end of each trial
        if i == length(trial_starts)
            trial_ends(i) = max(trialNum);
        else
            trial_ends(i) = trial_starts(i+1)-1;
        end
        % was stimulus target or distractor
        was_target = false;
        if sum(wasTarget(trial_starts(i):trial_ends(i)))
            was_target = true;
        end
        % determine outcome 
        if was_target && sum(rewardTrigger(trial_starts(i):trial_ends(i)))
            sprintf('Trial %i target: correct', i)
        elseif was_target
            sprintf('Trial %i target: incorrect', i)
        elseif sum(numLicks)% need to distinguish correct rejection from false alarm
            sprintf('Trial %i distractor: incorrect', i)
        else
            sprintf('Trial %i distractor: correct', i)
        end
    end
end