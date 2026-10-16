function DM = nexOp_buildSupervisedDM(X, Y, tVar, edges)
% Build a "supervised"-format DM struct directly from an already-built
% X/Y — the needsHR path (reduce-then-pool, see WIP.md #3) bypasses
% stat2dm_supervised entirely since X is already reduced+pooled by the
% time this is called; mirrors stat2dm_supervised's own label-encoding
% exactly, so DM.K.(tVar) has the same shape either path produces. Y
% quantization itself (nexOp_quantizeY) must already have happened
% upstream, once — edges here is just carried through into DM.K for
% scoreFold/scoreFoldDM to discretize held-out Y consistently.
%
%   X, Y  : already reduced/pooled feature matrix and (possibly
%           quantized) label vector
%   tVar  : target variable name (char/string)
%   edges : nexOp_quantizeY's bin edges (empty when Y wasn't quantized)
%
%   DM.X, DM.Y, DM.K.(tVar) — same shape as stat2dm_supervised's output
    labels_unique = unique(Y);
    key.code  = 1:numel(labels_unique);
    key.label = labels_unique;
    key.edges = edges;
    DM.X = X;
    DM.Y = nexOp_labelEncode(Y);
    DM.K.(tVar) = key;
end
