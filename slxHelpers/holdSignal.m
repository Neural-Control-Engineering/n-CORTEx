function [sigPulse] = holdSignal(onset_trig, sigAmp, sigPulseLen, t) 
    % When the trigger onset_trig is received, it sets sigPulse to sigAmp and 
    % stores the current time t in the persistent variable t0.   
    
    % If the trigger is not received (onset_trig is false), it checks whether t0 is not 
    % empty (indicating that a trigger has been received previously). 
    % If t0 is not empty, it checks if (t - t0) is less than 1.5 seconds. 
    % If so, it keeps sigPulse set to 1, maintaining the pulse for 1.5 seconds after the trigger. 
    
    % After 1.5 seconds have passed since the trigger was received (when (t - t0) is 
    % greater than or equal to 1.5 seconds), it clears the persistent variable 
    % t0, effectively resetting it to its initial condition.     
    
    persistent t0;
    if onset_trig                
        sigPulse = sigAmp; % set tone pulse high until 1.5 s elapses            
        % pulseEnd=0;
        t0 = t; % store current time 
    elseif ~isempty(t0) 
        if (t - t0) < sigPulseLen
            sigPulse = sigAmp;
            % pulseEnd=0;
        else
            sigPulse = 0;
            % pulseEnd=1;
            clear t0 % reset t0 to initial condition
        end        
    else % reset to 0 if no more trigger activity
        sigPulse = 0; 
        % pulseEnd=0;
    end
end