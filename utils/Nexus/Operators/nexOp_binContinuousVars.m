function Y = nexOp_binContinuousVars(Y, compareVars, nBins)
% Quantile-bin continuous compareVar columns in Y before enumeration.
% Replaces numeric values with '<col>_q<b>(<bin mean>)' labels.
% Columns that are already categorical (non-numeric or <= nBins unique values)
% are left unchanged.
    for ci = 1:numel(compareVars)
        col = char(strrep(compareVars(ci), "--", "_"));
        if ~ismember(col, Y.Properties.VariableNames), continue; end
        raw = Y.(col);
        if ~isnumeric(raw)
            numTry = str2double(string(raw));
            if any(~isnan(numTry)), raw = numTry; end
        end
        if ~isnumeric(raw) || ~nexOp_isContinuousVar(raw) || numel(unique(raw(~isnan(raw)))) <= nBins
            continue;
        end
        vals   = raw(~isnan(raw));
        edges  = quantile(vals, linspace(0, 1, nBins + 1));
        edges(end) = edges(end) + abs(edges(end)) * 1e-10 + 1e-10;
        binIdx = discretize(raw, edges);
        labels = strings(numel(raw), 1);
        for b = 1:nBins
            m = binIdx == b;
            if any(m)
                % labels(m) = sprintf('%s_q%d(%.3g)', col, b, mean(raw(m), 'omitnan'));
                labels(m) = sprintf('q%d(%.3g)', b, mean(raw(m), 'omitnan'));
            end
        end
        labels(isnan(raw)) = "<NaN>";
        Y.(col) = labels;
    end
end
