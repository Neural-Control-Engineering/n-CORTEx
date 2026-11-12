function T = nexPlot_ssmEigenSweep(mdlObj, dt_s, opts)
% nexPlot_ssmEigenSweep  Eigenspectra + timescales for every fitSWPGrid cell.
%
% T = nexPlot_ssmEigenSweep(mdlObj, dt_s)
% T = nexPlot_ssmEigenSweep(mdlObj, dt_s, regionField="unit", epochField="t", ...)
%
% Reads mdlObj.comboFits (populated by mdlObject.fitSWPGrid) -- each cell's
% fitted dynamics matrix A from child.SYS.DF_A.df -- and converts every
% eigenvalue lambda = r*exp(i*theta) to physical units:
%   tau_ms = -dt*1e3 / ln(r)      decay timescale (Inf if r >= 1)
%   f_Hz   = |theta| / (2*pi*dt)  rotation frequency (0 for real eigenvalues)
% Eigenvalues are invariant to the latent basis, so these are comparable
% across separately fitted cells.
%
%   dt_s        : seconds per SSM timestep AFTER pooling (e.g. 0.005 for
%                 unpooled 5 ms spike bins; 5 ms x pMap.t divsPerBin otherwise)
%   regionField : swpVal field holding the region label   (default "unit")
%   epochField  : swpVal field holding the epoch label    (default "t")
%   epochOrder  : x-axis order for epochs                 (default before/during/after)
%   colorBy     : comboFits.key field to color lines by in the tau figure
%                 (e.g. "responseThreshold"); "" = full CTG combo label
%   doPlot      : draw figures (default true)
%
% T : one row per (cell x eigenvalue): cell, ctg, region, epoch, eigIdx,
%     lambda, r, theta, tau_ms, f_Hz, isDominant (max r within the cell).
%
% Figures:
%   1) Complex plane per region, unit circle, eigenvalues colored by epoch.
%   2) Dominant tau per region across epochs, one line per CTG combo
%      (H1: critical slowing down = tau rising toward the withdrawal epoch).
%
% Caveat: 25 ms Gaussian rate smoothing floors tau -- read RELATIVE changes,
% and only trust tau well above ~25-50 ms.

    arguments
        mdlObj
        dt_s (1,1) double {mustBePositive}
        opts.regionField (1,1) string = "unit"
        opts.epochField  (1,1) string = "t"
        opts.epochOrder  (1,:) string = ["before","during","after"]
        opts.colorBy     (1,1) string = ""
        opts.regions     (1,:) string = string.empty   % subset/order of regions to plot ([] = all)
        opts.rhoClip     (1,1) double = 0.95           % lgssm_dynamax rho(A) clip ceiling
        opts.printTable  (1,1) logical = false
        opts.doPlot      (1,1) logical = true
    end

    fits = mdlObj.comboFits;
    if isempty(fits)
        error('nexPlot_ssmEigenSweep:noFits', 'mdlObj.comboFits is empty -- run fitSWPGrid first.');
    end

    % ── Resolve colorBy against the actual key field names ───────────────
    % Never fall back silently: an unmatched name would collapse every cell
    % into one category. Exact match first, then a unique case-insensitive
    % partial match (e.g. "threshold" -> "responseThreshold_q"), else error.
    if opts.colorBy ~= ""
        keyFields = string(fieldnames(fits(1).key));
        if ~ismember(opts.colorBy, keyFields)
            hit = keyFields(contains(lower(keyFields), lower(opts.colorBy)));
            if numel(hit) == 1
                fprintf('[nexPlot_ssmEigenSweep] colorBy "%s" -> key field "%s"\n', opts.colorBy, hit);
                opts.colorBy = hit;
            else
                error('nexPlot_ssmEigenSweep:colorBy', ...
                    'colorBy "%s" matches %d key fields. Available key fields: %s', ...
                    opts.colorBy, numel(hit), strjoin(keyFields, ', '));
            end
        end
    end

    % ── Collect eigenvalues per cell ──────────────────────────────────────
    rows = {};
    for k = 1:numel(fits)
        try
            A = fits(k).child.SYS.DF_A.df;
        catch
            warning('nexPlot_ssmEigenSweep:noA', 'cell %d has no SYS.DF_A -- skipped.', k);
            continue;
        end
        lam    = eig(A);
        r      = abs(lam);
        theta  = abs(angle(lam));
        tau_ms = -dt_s * 1e3 ./ log(r);
        tau_ms(r >= 1) = Inf;
        f_Hz   = theta / (2*pi*dt_s);
        [~, iDom] = max(r);

        ctg    = local_structLabel(fits(k).key);
        colorV = ctg;
        if opts.colorBy ~= ""
            colorV = local_field(fits(k).key, opts.colorBy);
        end
        region = local_field(fits(k).swpVal, opts.regionField);
        epoch  = local_field(fits(k).swpVal, opts.epochField);

        for e = 1:numel(lam)
            rows(end+1, :) = {k, ctg, colorV, region, epoch, e, lam(e), r(e), ...
                              theta(e), tau_ms(e), f_Hz(e), e == iDom}; %#ok<AGROW>
        end
    end
    T = cell2table(rows, 'VariableNames', {'cell','ctg','colorBy','region','epoch', ...
        'eigIdx','lambda','r','theta','tau_ms','f_Hz','isDominant'});

    % ── Fit-health flags (per cell, from the dominant mode) ──────────────
    %   failed : A is all zeros (every |lambda| = 0) -- fit did not run/collapsed
    %   atClip : dominant |lambda| sits on the rho(A) clip ceiling -- the true
    %            timescale is CENSORED (>= clip tau), not measured
    T.failed = false(height(T), 1);
    T.atClip = false(height(T), 1);
    for k = unique(T.cell)'
        sel  = T.cell == k;
        rMax = max(T.r(sel));
        T.failed(sel) = rMax == 0;
        T.atClip(sel) = abs(rMax - opts.rhoClip) < 1e-6;
    end
    D = T(T.isDominant, {'ctg','region','epoch','r','tau_ms','f_Hz','failed','atClip'});
    nCell = height(D);
    tauClip = -dt_s*1e3 / log(opts.rhoClip);
    fprintf(['[nexPlot_ssmEigenSweep] %d cell(s), dt = %.4g s\n' ...
             '  failed (A = 0)          : %d (%.0f%%)\n' ...
             '  at rho clip %.3g (tau = %.1f ms, censored): %d (%.0f%%)\n' ...
             '  measured                : %d (%.0f%%)\n'], ...
        nCell, dt_s, nnz(D.failed), 100*mean(D.failed), opts.rhoClip, tauClip, ...
        nnz(D.atClip), 100*mean(D.atClip), nnz(~D.failed & ~D.atClip), 100*mean(~D.failed & ~D.atClip));
    if mean(D.atClip) > 0.5
        warning('nexPlot_ssmEigenSweep:clipped', ...
            ['Most dominant modes sit on the rho(A) clip -- tau_dom reflects the clip, not the data. ' ...
             'Raise the clip in lgssm_dynamax.py (e.g. 0.999) and/or pool t to a coarser dt before interpreting.']);
    end
    if any(D.failed)
        fprintf('  failed cells:\n'); disp(unique(D(D.failed, {'ctg','region'}), 'rows'));
    end
    if opts.printTable, disp(D); end

    if ~opts.doPlot, return; end

    % Plot only healthy cells, restricted to the requested regions.
    T = T(~T.failed, :);
    if ~isempty(opts.regions)
        T = T(ismember(T.region, opts.regions), :);
    end

    % ── Shared encodings ──────────────────────────────────────────────────
    % Fixed-order categorical palette (validated default, light mode).
    pal = ["#2a78d6","#eb6834","#1baf7a","#eda100","#e87ba4","#008300","#8a63d2","#7a7a7a"];
    pal = cell2mat(arrayfun(@(h) sscanf(char(extractAfter(h,1)), '%2x%2x%2x')'/255, pal(:), 'UniformOutput', false));

    if ~isempty(opts.regions)
        regions = opts.regions(ismember(opts.regions, T.region));
    else
        regions = unique(T.region, 'stable');
    end
    epochs  =[opts.epochOrder(ismember(opts.epochOrder, T.epoch)), ...
               reshape(setdiff(unique(T.epoch, 'stable'), opts.epochOrder, 'stable'), 1, [])];
    nR      = numel(regions);
    nCol    = min(nR, 4);
    nRow    = ceil(nR / nCol);

    % ── Figure 1: complex plane per region, colored by epoch ─────────────
    % Zoomed to the data: eigenvalues of interest cluster near |lambda| = 1,
    % where a full-circle view stacks every epoch on top of each other.
    mk  = ["o","s","^","d","v","p","h","<"];   % epoch marker = secondary encoding
    sz  = [nCol*290, nRow*270 + 40];
    f1 = figure('Name', 'SSM eigenvalues by region', 'Color', 'w', 'Position', [100 100 sz]);
    tl = tiledlayout(f1, nRow, nCol, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, 'LGSSM eigenvalues, zoomed (gray arc = unit circle |\lambda| = 1)');
    ang = linspace(0, 2*pi, 721);
    reAll = real(T.lambda); imAll = imag(T.lambda);
    xl = [max(-1.1, min(reAll) - 0.05), 1.03];
    yl = max(0.1, max(abs(imAll)) + 0.05) * [-1 1];
    for ri = 1:nR
        ax = nexttile(tl); hold(ax, 'on');
        plot(ax, cos(ang), sin(ang), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5, 'HandleVisibility', 'off');
        yline(ax, 0, 'Color', [0.9 0.9 0.9], 'HandleVisibility', 'off');
        for ei = 1:numel(epochs)
            sel = T.region == regions(ri) & T.epoch == epochs(ei);
            if ~any(sel), continue; end
            scatter(ax, real(T.lambda(sel)), imag(T.lambda(sel)), 64, pal(min(ei,8),:), 'filled', ...
                'Marker', mk(min(ei,8)), 'MarkerEdgeColor', 'w', 'LineWidth', 1, ...
                'MarkerFaceAlpha', 0.85, 'DisplayName', char(epochs(ei)));
        end
        xlim(ax, xl); ylim(ax, yl);
        title(ax, regions(ri)); xlabel(ax, 'Re \lambda'); ylabel(ax, 'Im \lambda');
        box(ax, 'off');
        if ri == 1
            lg = legend(ax, 'Box', 'off', 'Orientation', 'horizontal');
            lg.Layout.Tile = 'north';
        end
    end

    % ── Figure 2: dominant tau across epochs ─────────────────────────────
    % Thin lines = individual CTG combos (e.g. paw x subject), colored by
    % colorBy (e.g. threshold); bold line = geometric mean per colorBy group
    % (log-scale axis). Hollow markers = censored at the rho(A) clip.
    f2 = figure('Name', 'SSM dominant timescale by epoch', 'Color', 'w', 'Position', [120 120 sz]);
    tl2 = tiledlayout(f2, nRow, nCol, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl2, sprintf(['Dominant timescale \\tau = -\\Deltat / ln|\\lambda|   (\\Deltat = %g ms)' ...
        '   thin = combo, bold = geometric mean, hollow = at clip (\\tau \\geq %.0f ms)'], dt_s*1e3, tauClip));
    Dfull  = T(T.isDominant, :);
    groups = unique(Dfull.ctg, 'stable');
    cKeys  = unique(Dfull.colorBy, 'stable');
    if numel(cKeys) > 8
        warning('nexPlot_ssmEigenSweep:manyColors', ...
            '%d color groups > 8 -- groups beyond 8 drawn in gray. Set colorBy to a coarser field.', numel(cKeys));
    end
    for ri = 1:nR
        ax = nexttile(tl2); hold(ax, 'on');
        yline(ax, tauClip, ':', 'Color', [0.55 0.55 0.55], 'HandleVisibility', 'off');
        % thin per-combo lines
        for gi = 1:numel(groups)
            sel = find(Dfull.region == regions(ri) & Dfull.ctg == groups(gi));
            if isempty(sel), continue; end
            [~, ord] = ismember(Dfull.epoch(sel), epochs);
            [ord, si] = sort(ord); sel = sel(si);
            col = pal(min(find(cKeys == Dfull.colorBy(sel(1))), 8), :);
            plot(ax, ord, Dfull.tau_ms(sel), '-', 'Color', [col 0.35], 'LineWidth', 1, 'HandleVisibility', 'off');
            clipd = Dfull.atClip(sel);
            scatter(ax, ord(~clipd), Dfull.tau_ms(sel(~clipd)), 18, col, 'filled', 'MarkerFaceAlpha', 0.5, 'HandleVisibility', 'off');
            scatter(ax, ord(clipd),  Dfull.tau_ms(sel(clipd)),  18, col, 'MarkerEdgeAlpha', 0.5, 'HandleVisibility', 'off');
        end
        % bold geometric-mean line per colorBy group
        for ci = 1:numel(cKeys)
            col = pal(min(ci, 8), :);
            gm  = NaN(1, numel(epochs)); nG = 0;
            for ei = 1:numel(epochs)
                sel = Dfull.region == regions(ri) & Dfull.colorBy == cKeys(ci) & Dfull.epoch == epochs(ei) & isfinite(Dfull.tau_ms);
                if any(sel), gm(ei) = exp(mean(log(Dfull.tau_ms(sel)))); nG = max(nG, nnz(sel)); end
            end
            if all(isnan(gm)), continue; end
            plot(ax, 1:numel(epochs), gm, '-o', 'Color', col, 'MarkerFaceColor', col, 'MarkerEdgeColor', 'w', ...
                'MarkerSize', 7, 'LineWidth', 2.5, 'DisplayName', sprintf('%s (n=%d)', cKeys(ci), nG));
        end
        set(ax, 'XTick', 1:numel(epochs), 'XTickLabel', epochs, 'XTickLabelRotation', 0, 'YScale', 'log');
        xlim(ax, [0.7, numel(epochs) + 0.3]);
        title(ax, regions(ri)); ylabel(ax, '\tau_{dom} (ms)');
        if ri == 1
            lg = legend(ax, 'Box', 'off', 'Interpreter', 'none', 'Orientation', 'horizontal');
            lg.Layout.Tile = 'north';
        else
            legend(ax, 'off');
        end
        ax.YGrid = 'on'; ax.YMinorGrid = 'off'; ax.GridColor = [0.9 0.9 0.9]; ax.GridAlpha = 1; box(ax, 'off');
    end
end


% ── Local helpers ────────────────────────────────────────────────────────
function s = local_structLabel(st)
% "fieldA=val | fieldB=val" for a (possibly empty) key struct.
    if isempty(st) || ~isstruct(st) || isempty(fieldnames(st))
        s = "all"; return;
    end
    fn = string(fieldnames(st));
    parts = arrayfun(@(f) string(st.(f)), fn);
    s = strjoin(parts, " | ");
end

function v = local_field(st, name)
% String value of st.(name), or "" when absent.
    v = "";
    if isstruct(st) && isfield(st, name)
        v = string(st.(name));
    end
end
