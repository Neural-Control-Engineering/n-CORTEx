function [tensorSlice, fSlice] = formatSpecParamTensor(df_spec, ax)
     % get frequency specific params across time
    t = ax.t;
    f = ax.f;
    tensorSlice= [];
    fSlice = [];
    CF_idxs = [1:(size(df_spec,1)-2)/3] .* 3;
    % for each frequency    
    for i = 1:size(f,2)
        freq = f(i);
        specSignalVector = zeros(size(t,1),size(t,2)*2);
        % find peaks of freq-interest along time
        [peakSlotNums, matchColIdxs] = locateSpecParamPeaks(df_spec, freq);
        m=1; % time step
        % arrange into time slice
        for j = matchColIdxs
            peakNum = peakSlotNums{(j+1)/2};
            specSignalVector(j) = df_spec(CF_idxs(peakNum)+1,m);
            specSignalVector(j+1) = df_spec(CF_idxs(peakNum)+2,m);
            m=m+1;
        end        
        % append to tensorSlice
        tensorSlice = cat(1,tensorSlice, specSignalVector);
        fSlice = [fSlice; freq];
        
    end
end