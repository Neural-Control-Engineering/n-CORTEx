function [IPD_A, IPD_B, PC_B] = validate_temporalPrecision(synch1, synch2, Fs1, Fs2, F_synch1, F_synch2, args)

    % CFG HEADER
    groupSize = args.groupSize; % default = 10

    % if isempty(validationFigure)
    %     validationFigure.fh = uifigure("Position",[50,50,600,300],"Color",[0,0,0]);
    %     validationFigure.panel1.ph = uipanel(validationFigure.fh,"Position",[5,5,500,290],"BackgroundColor",[0,0,0]);
    %     validationFigure.panel1.tiles.t = tiledlayout(validationFigure.panel1.ph,1,1);    
    % end
    
    % groupSize : number of pulse-periods to include in each precision
    % validation epoch
    % Fs : system sampling rate    
    % synch1 : external synchronization pulser
    % F_synch1 : expected pulser frequency for synch1
    % synch2 : internally generated synchronization pulser
    % F_synch2 : expected pulser frequency for synch2

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
        tB = t1;
    end
    
    % Report metrics 
    % rising edges (A)
    idx_risingEdgeA = diff(synchA) > 0;
    idx_risingEdgeB = diff(synchB) > 0;
    t_risingEdgeA = tA(idx_risingEdgeA);
    t_risingEdgeB = tB(idx_risingEdgeB);    
    % falling edges (A)
    idx_fallingEdgeA = diff(synchA) < 0;
    idx_fallingEdgeB = diff(synchB) < 0;
    t_fallingEdgeA = tA(circshift(idx_fallingEdgeA,1));
    t_fallingEdgeB = tB(idx_fallingEdgeB+1);    
    % count number of rising edges of B in A       
    % B:  
    PC_B = countPulsesContained(t_risingEdgeA, t_risingEdgeB, groupSize);
    % plot group-wise and total-trial inter-pulse-delay stats
    % A:  
    IPD_A = measureInterPulseDelay(t_risingEdgeA, groupSize);
    IPD_A.t_RE = t_risingEdgeA;
    % B:    
    IPD_B = measureInterPulseDelay(t_risingEdgeB, groupSize);
    IPD_B.t_RE = t_risingEdgeB;
end