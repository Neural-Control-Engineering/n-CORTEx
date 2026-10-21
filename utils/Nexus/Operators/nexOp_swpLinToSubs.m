function subs = nexOp_swpLinToSubs(si, dims)
% Decompose one linear SWP grid index into per-axis subscripts (mixed-radix,
% axis 1 fastest-varying) — the Cartesian-product primitive behind a
% multi-axis SWP sweep. Extracted from nexAnalysis_cvPermute.m's own local
% swpLinToSubs (DRY — also used by mdlObject.fitSWPGrid's multi-axis SWP
% grid; behavior unchanged, just no longer duplicated).
%
%   si   : linear index, 1..prod(dims)
%   dims : (1 x nAxes) candidate-value counts, one per SWP axis
%
%   subs : (1 x nAxes) per-axis subscript, 1-based
    nd   = numel(dims);
    subs = ones(1, nd);
    rem  = si - 1;
    for d = 1:nd
        subs(d) = mod(rem, dims(d)) + 1;
        rem     = floor(rem / dims(d));
    end
end
