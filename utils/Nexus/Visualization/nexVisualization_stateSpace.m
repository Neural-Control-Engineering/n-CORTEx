function nexVisualization_stateSpace(nexObj, ~)
    % Data-tier update: only set() on existing handles.  Never creates or
    % deletes scatter3 objects — that is rebuildTrackers()'s job.
    % t_total = tic;

    %% Guard
    if isempty(nexObj.STATE) || ~isfield(nexObj.STATE, 'Z') || isempty(nexObj.STATE.Z)
        return;
    end
    STATE = nexObj.STATE;
    gfx   = nexObj.Figure.panel0.tiles.graphics;
    ax    = nexObj.Figure.panel0.tiles.ax;
    if ~isfield(gfx, 'canvas') || isempty(gfx.canvas) || ~isvalid(gfx.canvas)
        return;
    end

    %% Latent column indices (X / Y / Z of scatter3)
    % Read directly from the Domain selectionBus — domain.F is not consulted.
    domSel = nex_returnSelectionMask(nexObj.collector.Domain);
    fSel   = string(domSel.F);
    d1Ax   = char(domSel.D1);
    animAx = char(nexObj.domain.animate);
    if isempty(fSel) || isequal(fSel, ""), return; end

    if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
            && isfield(nexObj.DF_postOp.ax, 'latent')
        latentList = string(nexObj.DF_postOp.ax.latent);
    else
        latentList = "z" + string(1:size(STATE.Z, 2));
    end
    [~, fIdx] = ismember(fSel, latentList);
    fIdx = fIdx(fIdx > 0);
    if numel(fIdx) < 2, return; end

    % Pad to 3 columns with zeros when only 2 latents are selected
    Z_full = STATE.Z(:, fIdx);
    if numel(fIdx) == 2
        Z_full = [Z_full, zeros(size(Z_full, 1), 1)];
    end

    %% View selections
    viewSel  = nex_returnSelectionMask(nexObj.collector.View);
    vwGroups = string(viewSel.VW);
    clrCols  = string(viewSel.CLR);
    clrCols  = clrCols(clrCols ~= "");   % strip empty entries from no-selection

    gCols = STATE.G.Properties.VariableNames;
    hasClrCol = ~isempty(clrCols) && ismember(clrCols(1), gCols);

    % AVG selection can be multi-valued (one string per selected group column).
    % Filter to names that actually exist in STATE.G.
    groupCols_vis = string(viewSel.AVG);
    groupCols_vis = groupCols_vis(groupCols_vis ~= "" & ismember(groupCols_vis, gCols));
    nGC           = numel(groupCols_vis);

    % For each VW value, record which group column owns it (0 = unmatched).
    % Look up against nexObj.AVG (N_groups rows) not STATE.G (N_rows) — avoids
    % O(N_rows × nGC) string conversions and unique() calls in the hot path.
    vw_col_idx = zeros(numel(vwGroups), 1, 'int32');
    if nGC > 0 && ~isequal(vwGroups, "") && ~isempty(vwGroups) ...
            && ~isempty(nexObj.AVG) && istable(nexObj.AVG)
        avgVarNames = nexObj.AVG.Properties.VariableNames;
        for ci = 1:nGC
            col = char(groupCols_vis(ci));
            if ~ismember(col, avgVarNames), continue; end
            uniq_ci = unique(string(nexObj.AVG.(col)));
            for i = 1:numel(vwGroups)
                if vw_col_idx(i) == 0 && any(uniq_ci == vwGroups(i))
                    vw_col_idx(i) = int32(ci);
                end
            end
        end
    end

    %% VW row mask — AND intersection across group columns
    % Selecting "pre" (phase) AND "thresh_q2(…)" (threshold) shows only rows
    % where phase=pre AND threshold=q2.  Columns with no VW match are unconstrained.
    if ~isequal(vwGroups, "") && ~isempty(vwGroups) && nGC > 0
        mask_VW = true(height(STATE.G), 1);
        for ci = 1:nGC
            sel_col = vwGroups(vw_col_idx == ci);   % VW values for this column
            if isempty(sel_col), continue; end
            mask_VW = mask_VW & ismember(string(STATE.G.(char(groupCols_vis(ci)))), sel_col);
        end
    else
        mask_VW = true(height(STATE.G), 1);
    end

    % fprintf('[vis] VW mask:      %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% Pointer mask — restrict rows to selected axis values.
    % STATE.G has axis value columns (t, ch, f, ...) added by buildSTATE.
    % For each Pointer axis, keep only rows whose axis value is selected.
    mask_ptr = true(height(STATE.G), 1);
    if ~isempty(nexObj.collector.Pointer)
        % t_rsel = tic;
        ptrSel  = nex_returnSelectionMask(nexObj.collector.Pointer);
        % fprintf('[vis]   returnSelectionMask: %.1f ms  (nAxes=%d)\n', toc(t_rsel)*1e3, numel(fieldnames(ptrSel)));
        ptrAxes = fieldnames(ptrSel);
        for k = 1:numel(ptrAxes)
            f   = ptrAxes{k};
            sel = ptrSel.(f);
            if ~isempty(sel) && ~isequal(sel, "") && ismember(f, gCols)
                % t_ptr = tic;
                if isnumeric(sel)
                    mask_f = ismembertol(double(STATE.G.(f)), double(sel(:)), 1e-3);
                else
                    mask_f = false(height(STATE.G), 1);
                    for j = 1:numel(sel)
                        mask_f = mask_f | strcmp(STATE.G.(f), char(sel(j)));
                    end
                end
                mask_ptr = mask_ptr & mask_f;
                if sum(mask_ptr)==0
                    keyboard
                end
                % fprintf('[vis]   ptr.%s: %.1f ms  (numel(sel)=%d, type=%s)\n', ...
                %     f, toc(t_ptr)*1e3, numel(sel), class(sel));
            end
        end
    end

    % fprintf('[vis] Pointer mask: %.1f ms\n', toc(t0)*1e3);
    % t0 = tic;
    %% D1 context window
    mask_d1 = true(height(STATE.G), 1);
    if ~isempty(d1Ax) && ismember(d1Ax, gCols) ...
            && ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ptr') ...
            && isprop(nexObj.DF_postOp.ptr, d1Ax) && isfield(nexObj.DF_postOp.ax, d1Ax)
        d1Ptr    = nexObj.DF_postOp.ptr.(d1Ax);
        d1Axis   = nexObj.DF_postOp.ax.(d1Ax);
        curIdx   = d1Ptr.value;
        half     = round(d1Ptr.window / 2);
        d1Start  = d1Axis(max(1, curIdx - half));
        d1End    = d1Axis(min(numel(d1Axis), curIdx + half));
        d1Vals_G = double(STATE.G.(d1Ax));
        d1Tol    = 0;
        if numel(d1Axis) > 1, d1Tol = abs(d1Axis(2) - d1Axis(1)) * 0.01; end
        mask_d1  = d1Vals_G >= d1Start - d1Tol & d1Vals_G <= d1End + d1Tol;
    end

    % fprintf('[vis] D1 mask:      %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% ANI pointer + after-image window
    len_afterImage = 5;
    if ~isempty(nexObj.cfg) && isfield(nexObj.cfg, 'aniCfg') ...
            && ~isempty(nexObj.cfg.aniCfg) && ~isempty(nexObj.cfg.aniCfg.entryParams)
        ep = nexObj.cfg.aniCfg.entryParams;
        if isfield(ep, 'len_afterImage') && ~isempty(ep.len_afterImage)
            len_afterImage = ep.len_afterImage;
        end
    end
    winStart_ani = -Inf;
    winEnd_ani   =  Inf;
    aniTol       = 0;      % tolerance for float-mismatched time axes (set below)
    if ~isempty(animAx) && ~isempty(nexObj.DF_postOp) ...
            && isprop(nexObj.DF_postOp, 'ptr') && isprop(nexObj.DF_postOp.ptr, animAx) ...
            && isfield(nexObj.DF_postOp.ax, animAx)
        aPtr         = nexObj.DF_postOp.ptr.(animAx);
        aniAxis      = nexObj.DF_postOp.ax.(animAx);
        curIdx       = aPtr.value;
        winEnd_ani   = aniAxis(curIdx);
        winStart_ani = aniAxis(max(1, curIdx - len_afterImage));
        % STATE.G time values come from averaged-DF ax, which accumulates
        % slightly different float rounding from DF_postOp.ax.  Use 1% of the
        % axis step as tolerance — far larger than any rounding error, far
        % smaller than the actual sample spacing.  Only numeric range masks use
        % this; strcmp-based category comparisons are unaffected.
        if numel(aniAxis) > 1
            aniTol = abs(aniAxis(2) - aniAxis(1)) * 0.01;
        end
    end

    % fprintf('[vis] ANI window:   %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% Subset to selected rows — all per-point work below is O(N_selected)
    mask_canvas = mask_VW & mask_ptr & mask_d1;
    G_sel  = STATE.G(mask_canvas, :);
    Z_vis  = Z_full(mask_canvas, :);
    nSel   = height(G_sel);

    % fprintf('[vis] Subset:       %.1f ms  (N_total=%d → N_sel=%d)\n', toc(t0)*1e3, height(STATE.G), nSel); t0 = tic;
    %% Color map — two-pass hybrid: LUT columns blended in RGB, non-LUT columns
    % tuned in HSV.
    %
    % Pass 1 (RGB): every selected CLR column that has a LUT entry contributes
    % an Nx3 color layer.  Layers are averaged; when >1 the result is normalized
    % to max-channel=1 so the blended hue stays vivid before the D1 gradient.
    % Averaging is commutative — selection order never affects the result.
    %
    % Pass 2 (HSV saturation): every CLR column with no LUT modulates the
    % saturation of the Pass-1 base color.  Unique values are mapped linearly
    % to S ∈ [0.35, 1.0] in stable sort order, so the base hue is preserved
    % while the unmapped dimension adds a perceptible tonal gradient.
    if hasClrCol
        C_lut   = {};   % Nx3 per LUT-mapped column
        hsv_mod = {};   % clrVals string vectors for non-LUT columns

        for ci = 1:numel(clrCols)
            col = char(clrCols(ci));
            if ~ismember(col, G_sel.Properties.VariableNames), continue; end
            clrVals  = string(G_sel.(col));
            C_ci     = zeros(nSel, 3);
            lutFound = false;
            try
                lut = nexObj.nexon.console.BASE.registry.LUT.(col);
                for k = 1:height(lut)
                    mask_k = clrVals == string(lut.label(k));
                    hex    = char(lut.color(k));
                    rgb    = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
                    C_ci(mask_k, :) = repmat(rgb, sum(mask_k), 1);
                end
                lutFound = true;
            catch
            end
            if lutFound
                C_lut{end+1} = C_ci;
            else
                hsv_mod{end+1} = clrVals;
            end
        end

        % Pass 1 — RGB blend of LUT columns
        if ~isempty(C_lut)
            C_sel = mean(cat(3, C_lut{:}), 3);
            if numel(C_lut) > 1
                maxC = max(C_sel, [], 2);
                maxC(maxC < eps) = 1;
                C_sel = C_sel ./ maxC;
            end
        else
            C_sel = repmat(nexObj.nexon.settings.Colors.cyberGreen, nSel, 1);
        end

        % Pass 2 — HSV hue-shift + vividness tuning for non-LUT columns.
        % H is rotated by a small per-group offset (spread ±hue_spread around
        % the base hue) so each group gets a distinct tint while staying in the
        % same color family.  S ramps from sat_lo to 1.0 (vividness).
        % V is left untouched; only a very slight lift is applied to the dimmest
        % group so nothing fully vanishes before the D1 gradient runs.
        if ~isempty(hsv_mod)
            hsv_sel    = rgb2hsv(C_sel);
            hue_spread = 1/12;   % ±half of this around base hue (~±15°)
            sat_lo     = 0.45;
            val_lo     = 0.80;   % subtle floor; groups above it keep their value
            for mi = 1:numel(hsv_mod)
                vals   = hsv_mod{mi};
                uniq_v = unique(vals, 'stable');
                n_u    = numel(uniq_v);
                t      = linspace(0, 1, max(n_u, 2));   % [0..1] per group
                h_off  = linspace(-hue_spread/2, hue_spread/2, max(n_u, 2));
                for k = 1:n_u
                    m = vals == uniq_v(k);
                    hsv_sel(m, 1) = mod(hsv_sel(m, 1) + h_off(k), 1);
                    hsv_sel(m, 2) = sat_lo + (1 - sat_lo) * t(k);
                    hsv_sel(m, 3) = max(hsv_sel(m, 3), val_lo + (1 - val_lo) * t(k));
                end
            end
            C_sel = hsv2rgb(hsv_sel);
        end
    else
        C_sel = repmat(nexObj.nexon.settings.Colors.cyberGreen, nSel, 1);
    end

    % fprintf('[vis] Color LUT:    %.1f ms\n', toc(t0)*1e3); t0 = tic;
    C_sel_pure = C_sel;   % snapshot before D1 gradient — used for legend swatches

    %% D1 brightness gradient — over selected rows only
    if ~isempty(d1Ax) && ismember(d1Ax, G_sel.Properties.VariableNames)
        d1Vals = double(G_sel.(d1Ax));
        d1Min  = min(d1Vals);
        d1Max  = max(d1Vals);
        if d1Max > d1Min
            minBright  = 0.15;
            brightness = minBright + (1 - minBright) * (d1Vals - d1Min) / (d1Max - d1Min);
            brightness = max(minBright, min(1.0, brightness));
            C_sel      = C_sel .* brightness;
        end
    end

    % fprintf('[vis] Brightness:   %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% Scatter size
    canvasSize  = 100;
    trackerSize = 150;
    if ~isempty(animAx) && ~isempty(nexObj.pMap) && isfield(nexObj.pMap, animAx)
        dpb = nexObj.pMap.(animAx).divsPerBin;
        if dpb > 1
            canvasSize  = canvasSize  * dpb;
            trackerSize = trackerSize * dpb;
        end
    end

    % fprintf('[vis] Scatter size: %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% Canvas
    set(gfx.canvas, ...
        'XData',    Z_vis(:,1), ...
        'YData',    Z_vis(:,2), ...
        'ZData',    Z_vis(:,3), ...
        'CData',    C_sel, ...
        'SizeData', canvasSize);

    % fprintf('[vis] Canvas set:   %.1f ms\n', toc(t0)*1e3); t0 = tic;
    ax.XLabel.String = char(fSel(1));
    ax.YLabel.String = char(fSel(2));
    if numel(fIdx) >= 3, ax.ZLabel.String = char(fSel(3)); end

    if ~isempty(animAx)
        axTitle = nexTract_axisTitle(nexObj, nexObj.DF_postOp, string(animAx));
        ax.Title.String = char(axTitle);
        ax.Title.Color  = nexObj.nexon.settings.Colors.cyberGreen;
    end

    % fprintf('[vis] Labels/title: %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% Tracker — per-VW-value after-image, operating on the canvas-visible subset
    % Each VW selection value gets its own tracker handle (built by rebuildTrackers).
    % To find which rows in G_sel match a given VW value, we search across all
    % group columns (same multi-column lookup used by the VW mask above).
    if isequal(vwGroups, ""), return; end

    % Safe struct field names for the same VW values used in rebuildTrackers
    activeFlds  = string(matlab.lang.makeValidName(cellstr(vwGroups)));
    aniVals_sel = double(G_sel.(animAx));
    mask_ani    = aniVals_sel >= winStart_ani - aniTol & aniVals_sel <= winEnd_ani + aniTol;

    for i = 1:numel(vwGroups)
        fld = char(activeFlds(i));
        if ~isfield(gfx.canvas_tracker, fld), continue; end
        if ~isvalid(gfx.canvas_tracker.(fld)), continue; end

        mask_grp = mask_ani;
        ci = vw_col_idx(i);
        if ci > 0
            mask_grp = mask_grp & ismember(string(G_sel.(char(groupCols_vis(ci)))), vwGroups(i));
        end

        Z_grp = Z_vis(mask_grp, :);
        if isempty(Z_grp)
            set(gfx.canvas_tracker.(fld), 'XData', [], 'YData', [], 'ZData', []);
            continue;
        end

        hsv_grp = rgb2hsv(C_sel(mask_grp, :));
        recency = (aniVals_sel(mask_grp) - winStart_ani) / max(eps, winEnd_ani - winStart_ani);
        recency = max(0, min(1, recency));
        hsv_grp(:, 3) = min(1, 2 * recency);
        hsv_grp(:, 2) = max(0.5, (1 - recency) .^ 2);
        C_grp_vivid = hsv2rgb(hsv_grp);

        set(gfx.canvas_tracker.(fld), ...
            'XData',    Z_grp(:,1), ...
            'YData',    Z_grp(:,2), ...
            'ZData',    Z_grp(:,3), ...
            'CData',    C_grp_vivid, ...
            'SizeData', trackerSize);
    end

    % Scrub trackers for VW values no longer selected
    allFlds = fieldnames(gfx.canvas_tracker);
    for i = 1:numel(allFlds)
        fld = allFlds{i};
        if ~ismember(fld, activeFlds) && isvalid(gfx.canvas_tracker.(fld))
            set(gfx.canvas_tracker.(fld), 'XData', [], 'YData', [], 'ZData', []);
        end
    end

    %% Legend — update proxy swatch colors only when VW selection has changed
    % (skipped during animation frames where VW is stable)
    if isfield(gfx, 'legend_proxies')
        vwKey    = strjoin(vwGroups, '|');
        prevKey  = '';
        if isfield(nexObj.Figure.panel0.tiles.graphics, 'legend_vwCache')
            prevKey = nexObj.Figure.panel0.tiles.graphics.legend_vwCache;
        end
        if ~strcmp(vwKey, prevKey)
            for i = 1:numel(vwGroups)
                fld = char(activeFlds(i));
                if ~isfield(gfx.legend_proxies, fld) || ~isvalid(gfx.legend_proxies.(fld)), continue; end
                ci = vw_col_idx(i);
                if ci > 0
                    mask_grp_c = ismember(string(G_sel.(char(groupCols_vis(ci)))), vwGroups(i));
                else
                    mask_grp_c = true(nSel, 1);
                end
                if any(mask_grp_c)
                    clr = mean(C_sel_pure(mask_grp_c, :), 1);
                    mx  = max(clr);
                    if mx > 0, clr = clr / mx; end
                else
                    clr = nexObj.nexon.settings.Colors.cyberGreen;
                end
                set(gfx.legend_proxies.(fld), 'Color', clr, 'MarkerFaceColor', clr);
            end
            nexObj.Figure.panel0.tiles.graphics.legend_vwCache = vwKey;
        end
    end

    % fprintf('[vis] Tracker scrub:%.1f ms\n', toc(t0)*1e3);
    % fprintf('[vis] TOTAL:        %.1f ms\n', toc(t_total)*1e3);
end
