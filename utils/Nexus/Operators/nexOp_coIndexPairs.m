function pairs = nexOp_coIndexPairs(ax)
% Bootstrap registry for co-indexed axis pairs.
%
% PRIMARY USE: called once by dtsIO_composeDF to write DF.coIdx.
% At runtime, nexOp_coAlign reads DF.coIdx directly — this function is only
% invoked as a fallback for DFs that predate the coIdx field.
%
% To register a new pair, add it to allPairs. dtsIO_composeDF will filter
% to only pairs where both axes are present in the specific DF.
    allPairs = {{'chans', 'unit'}};
    pairs    = {};
    if nargin < 1 || isempty(ax), return; end
    axFields = fieldnames(ax);
    for p = 1:numel(allPairs)
        pair = allPairs{p};
        if all(ismember(pair, axFields))
            pairs{end+1} = pair;  %#ok<AGROW>
        end
    end
end
