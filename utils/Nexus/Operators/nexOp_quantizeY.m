function [Y_out, edges] = nexOp_quantizeY(Y_in, nBins)
% Quantile-quantize a continuous Y into nBins groups — same convention
% reportAverage uses (nexFigure_addAvgControls.m / nexObject.reportAverage).
% nBins=Inf (the default), or Y not numeric/continuous enough to bother
% quantizing, is a pass-through: Y_out=Y_in, edges=[].
%
% edges is the whole point of factoring this out: callers must reuse the
% SAME edges (computed from train Y only) to discretize test Y before
% scoring — quantizing train and never touching test produces predictions
% in bin-ID space compared against raw continuous test values, which
% silently scores as ~random regardless of true model quality.
    edges = [];
    Y_out = Y_in;
    if isnumeric(Y_in) && isfinite(nBins) && nexOp_isContinuousVar(Y_in) && ...
            numel(unique(Y_in(~isnan(Y_in)))) > nBins
        vals  = Y_in(~isnan(Y_in));
        edges = quantile(vals, linspace(0, 1, nBins + 1));
        edges(end) = edges(end) + abs(edges(end)) * 1e-10 + 1e-10;
        Y_out = discretize(Y_in, edges);
    end
end
