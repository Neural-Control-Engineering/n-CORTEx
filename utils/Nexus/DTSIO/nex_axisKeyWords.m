function kw = nex_axisKeyWords(customList)
% Return the canonical axis keyword list used across all DTSIO read/write paths.
%
% Called with no arguments to GET the current list (the normal case):
%   kw = nex_axisKeyWords()
%
% Called with a string array at startup to OVERRIDE the default:
%   nex_axisKeyWords(["f","t","chans","myNewAxis"])
%
% The default covers all recognised DF axis names. Extend here when adding
% a new axis type — one edit propagates to composeDF, readHDF5, writeDF_toHDF5,
% exportDTS, rechunkDTS, and sinkPatchCols automatically.

    persistent KW;
    if nargin > 0
        KW = string(customList(:)');   % always store as row vector
    end
    if isempty(KW)
        KW = ["f","t","chans","factor","dropout","latent","peak","param","unit","wf","measure"];
    end
    kw = KW;
end
