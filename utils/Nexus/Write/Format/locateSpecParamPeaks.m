function [peakSlotNums, matchColIdxs] = locateSpecParamPeaks(df_spec, freq)
    CF_idxs = [1:(size(df_spec,1)-2)/3] .* 3;            
    CF_vals = floor(df_spec(CF_idxs,:));
    CF_vals(CF_vals==0) = nan;
    freqMatchCols = (CF_vals==freq);            
    peakSlotNums = arrayfun(@(i) find(freqMatchCols(:,i)==1), [1:size(freqMatchCols,2)], "UniformOutput",false);
    freqMatchCols = any(freqMatchCols,1);  
    matchColIdxs = find(freqMatchCols==1).*2-1;
end