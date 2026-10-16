function names = spcpmIO_paramNames(maxPeaks)
% The FIXED, ordered parameter-name list for kernel_specparam_segmented_
% multiexp's args — OFF/EXP1-3/FC1-3 then maxPeaks CF/PW/BW triplets.
% Shared by nexObj_fitScope's saveFit (ax_fit.param — names df_fit's own
% trailing dimension) and spcpmIO_kernel2vector (flattening order), so
% the two always agree on which slot is which parameter.
%
%   maxPeaks : number of CF/PW/BW triplets to include
%   names    : 1 x (7 + maxPeaks*3) string array
    names = ["OFF", "EXP1", "EXP2", "EXP3", "FC1", "FC2", "FC3"];
    for p = 1:maxPeaks
        names = [names, sprintf("CF%d", p), sprintf("PW%d", p), sprintf("BW%d", p)]; %#ok<AGROW>
    end
end
