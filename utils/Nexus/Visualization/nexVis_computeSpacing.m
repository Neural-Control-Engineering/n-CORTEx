function ySpacing = nexVis_computeSpacing(traces, multiplier)
% Compute y-offset spacing between stacked traces.
% Uses median peak-to-peak amplitude across the trace set.
    pp = cellfun(@(t) max(double(t(:)), [], 'omitnan') - min(double(t(:)), [], 'omitnan'), traces);
    pp = pp(isfinite(pp) & pp > 0);
    if isempty(pp)
        ySpacing = 1;
    else
        ySpacing = median(pp) * multiplier;
    end
end
