function C_traces = nexVis_blendColors(C_traces, axClrCols, rowBaseColors, gi, nT)
% Blend per-trace ax-- colors with a group-level base color.
%
% If only group colors: replace entirely.
% If both: average then re-normalise so the brightest channel reaches 1.
    if isempty(rowBaseColors), return; end
    baseClr = repmat(rowBaseColors(gi,:), nT, 1);
    if isempty(axClrCols)
        C_traces = baseClr;
    else
        C_traces = (C_traces + baseClr) / 2;
        maxC = max(C_traces, [], 2);
        maxC(maxC < eps) = 1;
        C_traces = C_traces ./ maxC;
    end
end
