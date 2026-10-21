function fig = plot_mixedEffectViolin(results, stratum, band, chans, t, nexon)
% plot_mixedEffectViolin  Trial-level bandPower distribution for ONE grid
% cell (band x chans x t) within ONE CCI/side stratum, split by condition
% and nested by subject.
%
% Wraps the existing Draw/nexDraw_violin.m plainly -- it already does the
% right rendering (violin + raw jittered scatter overlay + error bars +
% nested multi-tier category labeling) and needs no "liveness"/re-nesting
% work for this use (see Nexus WIP.md #12 observation 4: that's a
% deferred optimization for when Pointer-driven scanning actually lands,
% not something day-1 drill-down needs). colorAx_green (called inside
% nexDraw_violin) applies its own dark/cyberGreen axis styling
% automatically -- this function matches the figure background to it
% rather than imposing a different palette, since the point is reusing
% the existing visual language, not inventing a new one.
%
%   results : the struct run_mixedEffectPipeline returns (uses .T, same
%           as plot_mixedEffectTrajectory.m) -- filtered via the SAME
%           stratifyMixedEffectT helper, so this draws from the exact
%           same rows that produced that stratum's build_bandHierarchy
%           output, never a second, independently-filtered subset.
%   stratum : one of "preCCI_L","preCCI_R","postCCI_L","postCCI_R".
%   band, chans, t : the one cell to drill into, as values appearing in
%           T's own categorical columns (e.g. "gamma", "VPM", "0.988").
%   nexon : optional, default []. Supplies nexon.settings.Colors.cyberGreen
%           as nexDraw_violin's error-bar color -- falls back to the same
%           literal startNexus.m/colorAx_green both already use if
%           omitted.
%
%   fig : the created figure handle.

    if nargin < 6, nexon = []; end

    if ~isfield(results, 'T')
        error('plot_mixedEffectViolin:noT', ...
            'results has no .T field -- expected run_mixedEffectPipeline''s own output struct.');
    end
    strataT = stratifyMixedEffectT(results.T);
    validStrata = ["preCCI_L", "preCCI_R", "postCCI_L", "postCCI_R"];
    if ~ismember(stratum, validStrata)
        error('plot_mixedEffectViolin:badStratum', ...
            'stratum "%s" not recognized -- expected one of: %s.', string(stratum), strjoin(validStrata, ', '));
    end
    T = strataT.(char(stratum));

    mask = T.band == band & T.chans == chans & T.t == t;
    Tc = T(mask, :);
    if height(Tc) == 0
        error('plot_mixedEffectViolin:noRows', ...
            'No rows in stratum "%s" for band="%s", chans="%s", t="%s".', ...
            string(stratum), string(band), string(chans), string(t));
    end
    Tc.subject   = categorical(string(Tc.subject));
    Tc.condition = categorical(string(Tc.condition));

    % STAT-shaped table nexDraw_violin.m expects: .df is the response
    % (plain numeric column here -- one scalar per row; the cell-array
    % form it also supports is for multi-sample-per-row data, not needed
    % here), plus one column per S_categories tier.
    %
    % Single-tier (condition only) deliberately, not condition+subject
    % nested: nexDraw_violin.m's own label-matching line (`L = arrayfun(@(x)
    % xLabels_sub(x==xTicks_sub), X, "UniformOutput",true)`) only checks
    % tier-1's ticks against the FULL multi-tier X encoding
    % nexStat_binSTAT builds -- any row whose X includes a nonzero
    % lower-tier offset fails to match and returns [] instead of a scalar,
    % which arrayfun's UniformOutput rejects. Confirmed by direct
    % reproduction (2-tier condition+subject call errors; condition alone
    % does not) -- a latent bug in nexDraw_violin.m itself, logged to
    % WIP.md #12 as a follow-up rather than fixed here under today's time
    % budget. Per-subject identity is genuinely NOT shown here as a
    % result (nexDraw_scatter.m colors every point by its violin group's
    % FaceColor, not per subject -- checked directly, not assumed) --
    % that's deliberately the trajectory figure's job
    % (plot_mixedEffectTrajectory.m), not duplicated here.
    STAT = table(Tc.bandPower, Tc.condition, 'VariableNames', {'df', 'condition'});
    S_categories = struct('C1', "condition");
    C_errorBar = resolveCyberGreen(nexon);

    fprintf('[plot_mixedEffectViolin] %s: band="%s", chans="%s", t="%s" (%d rows, %d subjects)\n', ...
        string(stratum), string(band), string(chans), string(t), height(Tc), numel(unique(Tc.subject)));

    TEXT_C = [0.90 0.90 0.90];
    fig = figure('Color', [0 0 0], 'Position', [100 100 700 560]);
    ax  = axes(fig);
    nexDraw_violin(ax, STAT, S_categories, C_errorBar);
    ylabel(ax, 'bandPower', 'Color', TEXT_C);
    title(ax, sprintf('%s | %s | %s | t=%s', string(stratum), string(band), string(chans), string(t)), ...
          'Color', TEXT_C, 'Interpreter', 'none');

    % Per-violin hard number (that group's own trial-level mean) plus a
    % subtitle pulling the cell's ACTUAL fixed-effect/corrected-p straight
    % from results.(stratum) -- the same build_bandHierarchy row behind
    % this cell's heatmap star -- rather than re-fitting a second time.
    condLevels = categories(Tc.condition);
    yl = ylim(ax);
    yTop = yl(2) - 0.06 * diff(yl);
    for ci = 1:numel(condLevels)
        gMean = mean(Tc.bandPower(Tc.condition == condLevels{ci}));
        text(ax, ci, yTop, sprintf('mean=%.3g', gMean), 'Color', TEXT_C, ...
            'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
    end
    statLine = '(no matching stratum results -- effect/p unavailable)';
    if isfield(results, char(stratum))
        Rstat = results.(char(stratum));
        rowMask = Rstat.band == band & Rstat.chans == chans & Rstat.t == t;
        if any(rowMask)
            rr = Rstat(find(rowMask, 1), :);
            statLine = sprintf('conditionEffect = %.3g, p_{corrected} = %.3g', ...
                rr.conditionEffect, rr.conditionEffect_p_corrected);
        end
    end
    subtitle(ax, statLine, 'Color', TEXT_C, 'Interpreter', 'tex');
    set(fig, 'InvertHardcopy', 'off');
end

function c = resolveCyberGreen(nexon)
% resolveCyberGreen  nexon.settings.Colors.cyberGreen when available,
% falling back to the same literal startNexus.m/colorAx_green both
% already use so this figure's error-bar color matches even without a
% live nexon.
    c = [0.24, 0.94, 0.46];
    if isempty(nexon), return; end
    try
        c = nexon.settings.Colors.cyberGreen;
    catch
    end
end
