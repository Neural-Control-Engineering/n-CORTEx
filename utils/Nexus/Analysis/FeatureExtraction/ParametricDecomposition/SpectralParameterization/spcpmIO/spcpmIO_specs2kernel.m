function kArgs = spcpmIO_specs2kernel(specs)
    % format: OFF, EXP1, EXP2, ... FC1, FC2, ... PE1, PE2, ...    
    kArgs.OFF=specs(1);
    % EXPONENT (max = 3)
    kArgs.EXP1=specs(2);
    kArgs.EXP2=specs(3);
    kArgs.EXP3=specs(4);
    % CORNER FREQ (max = 3)
    kArgs.FC1 = specs(5);
    kArgs.FC2 = specs(6);
    kArgs.FC3 = specs(7);
    % PERIODIC (triplets)
    for i = 8:3:length(specs)
        if i < (length(specs)-2)
            idx_peak = [i:i+2];        
            CF = specs(idx_peak(1));
            PW = specs(idx_peak(2));
            BW = specs(idx_peak(3));        
            peakNum = i - (8 - 1);
            CFID = sprintf("CF%d",peakNum);
            PWID = sprintf("PW%d",peakNum);
            BWID = sprintf("BW%d",peakNum);
            kArgs.(CFID) = CF;
            kArgs.(PWID) = PW;
            kArgs.(BWID) = BW;
        end
    end
        

end