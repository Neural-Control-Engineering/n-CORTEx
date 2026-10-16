function nexAudit_quantizeEdges(auditDir, comboDir, k, tVar, nBinsY, edgesY, Y_train_raw, ctgLabel)
% nexAudit_quantizeEdges  Write the per-fold target-quantization audit
% record — the actual quantile bin boundaries translated into
% human-readable ranges (e.g. "Quantile 1: responseThreshold in [a, b)"),
% plus a histogram of the fold's own (pooled, train-only) target values
% with those same boundaries drawn as vertical lines.
    if isempty(edgesY)
        qtxt = sprintf('nBins=%s: pass-through (target not continuous enough / nBins>=nUnique)\n', mat2str(nBinsY));
    else
        qLines = strings(numel(edgesY)-1, 1);
        for b = 1:(numel(edgesY)-1)
            qLines(b) = sprintf('Quantile %d: %s in [%.4g, %.4g%s', ...
                b, tVar, edgesY(b), edgesY(b+1), ')');
        end
        qLines(end) = extractBefore(qLines(end), ')') + "]";   % last bin is closed on the right
        qtxt = sprintf('nBins=%s, raw edges=%s\n%s\n', mat2str(nBinsY), mat2str(edgesY,6), strjoin(qLines, newline));
    end
    nexAudit_writeText(auditDir, fullfile(comboDir, sprintf('fold_%d', k), 'quantize_edges.txt'), qtxt);

    fig = figure('Visible', 'off'); hold on;
    histogram(Y_train_raw);
    if ~isempty(edgesY)
        for b = 1:numel(edgesY)
            xline(edgesY(b), 'r--', 'LineWidth', 1.5);
        end
    end
    hold off;
    title(sprintf('%s fold %d — train %s, quantile edges', ctgLabel, k, tVar), 'Interpreter', 'none');
    xlabel(tVar, 'Interpreter', 'none'); ylabel('pooled-row count');
    nexAudit_savePlot(auditDir, fullfile(comboDir, sprintf('fold_%d', k), 'tVar_train_hist_with_edges.png'), fig);
end
