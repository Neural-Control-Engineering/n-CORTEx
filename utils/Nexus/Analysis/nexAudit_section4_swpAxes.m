function nexAudit_section4_swpAxes(auditDir, swpAxes)
% nexAudit_section4_swpAxes  Write the Section 4 (SWP axis resolution)
% audit record — one summary line per swept axis (id/n/dim/coField), plus
% one <axisID>_edges.txt table per axis: window_idx | repr_value | range,
% where "range" is the human-readable start--end boundary (time windows)
% or the region/block name itself (feature-block axes — see swpAxes(a)
% .rangeLabel's own construction in nexAnalysis_cvPermute.m section 4).
% Resolved once, globally (from trial 1) — this writes once per run, not
% once per combo/fold.
    lines = strings(0, 1);
    for a = 1:numel(swpAxes)
        lines(end+1) = sprintf('axis "%s": n=%d, dim=%d, coField=%s', ...
            swpAxes(a).id, swpAxes(a).n, swpAxes(a).dim, swpAxes(a).coField); %#ok<AGROW>
    end
    nexAudit_writeText(auditDir, '04_swp_axes/swpAxes_summary.txt', strjoin(lines, newline));

    for a = 1:numel(swpAxes)
        idxCol = (1:swpAxes(a).n)';
        edgeTbl = table(idxCol, swpAxes(a).vals(:), swpAxes(a).rangeLabel(:), ...
            'VariableNames', {'window_idx', 'repr_value', 'range'});
        nexAudit_writeText(auditDir, sprintf('04_swp_axes/%s_edges.txt', swpAxes(a).id), evalc('disp(edgeTbl)'));
    end
end
