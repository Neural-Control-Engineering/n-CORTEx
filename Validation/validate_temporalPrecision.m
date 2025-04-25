function validate_temporalPrecision(synch1, synch2, Fs1, Fs2, F_synch1, F_synch2, args)

    % groupSize : number of pulse-periods to include in each precision
    % validation epoch
    % Fs : system sampling rate    
    % synch1 : external synchronization pulser
    % F_synch1 : expected pulser frequency for synch1
    % synch2 : internally generated synchronization pulser
    % F_synch2 : expected pulser frequency for synch2

    % CFG HEADER
    groupSize = args.groupSize; % default = 10

    % take two identically sampled 'synch' signals and 'compare' them
    % by counting the number of rising edges comprised in one (the faster
    % synch, synch2) by the other (the slower one, synch1, ususally external)

    % report average time between rising edges, plus std for each synch
    % (compare both?) - use groupSize here

    % generate a time vectors from Fs
    t1 = [0:length(synch1)-1] ./ Fs1;
    t2 = [0:length(synch2)-1] ./ Fs2;
    
    % Identify the slower synchronizer (as the lower F_synch)
    if F_synch1 < F_synch2
        synchA = synch1;
        synchB = synch2;
        tA = t1;
        tB = t2;
    else
        synchA = synch2;
        synchB = synch1;
        tA = t2;
        tB = t2;
    end
    
    % Report metrics 
    % rising edges (A)
    idx_risingEdgeA = diff(synchA) > 0;
end