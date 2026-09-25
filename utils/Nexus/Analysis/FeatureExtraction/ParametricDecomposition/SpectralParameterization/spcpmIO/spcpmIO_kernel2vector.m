function v = spcpmIO_kernel2vector(kArgs, paramNames)
% Flatten a kernel_args struct (as edited by nexObj_fitScope's spinner
% panel) into a plain vector, in EXACTLY paramNames' order — the row
% written into one (chan,t) slot of a df_fit volume. Inverse operation
% (vector -> struct, e.g. for re-loading a saved slot) is a simple
% struct(paramNames(i), v(i), ...) loop; no dedicated helper needed for
% that direction since it's a one-liner at the call site.
%
%   kArgs      : struct with (at least) every field in paramNames
%   paramNames : 1xN string array, e.g. spcpmIO_paramNames(maxPeaks)
%
%   v : 1xN double — 0 for any field paramNames names that kArgs doesn't
%       have (shouldn't happen after padPeakSlots, but kept defensive)
    v = zeros(1, numel(paramNames));
    for i = 1:numel(paramNames)
        f = paramNames(i);
        if isfield(kArgs, f)
            v(i) = kArgs.(f);
        end
    end
end
