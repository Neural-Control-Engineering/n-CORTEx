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
    groupCol = char(viewSel.AVG);
    vwGroups = string(viewSel.VW);
    clrCol   = char(viewSel.CLR);

    gCols = STATE.G.Properties.VariableNames;
    hasGroupCol = ~isempty(groupCol) && ismember(groupCol, gCols);
    hasClrCol   = ~isempty(clrCol)   && ismember(clrCol,   gCols);

    % t0 = tic;
    %% VW row mask
    if hasGroupCol && ~isequal(vwGroups, "")
        groupVals = STATE.G.(groupCol);
        mask_VW   = false(height(STATE.G), 1);
        for k = 1:numel(vwGroups)
            mask_VW = mask_VW | strcmp(groupVals, char(vwGroups(k)));
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
                    mask_f = ismembertol(double(STATE.G.(f)), double(sel(:)), 1e-6);
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
        mask_d1  = d1Vals_G >= d1Start & d1Vals_G <= d1End;
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
    if ~isempty(animAx) && ~isempty(nexObj.DF_postOp) ...
            && isprop(nexObj.DF_postOp, 'ptr') && isprop(nexObj.DF_postOp.ptr, animAx) ...
            && isfield(nexObj.DF_postOp.ax, animAx)
        aPtr         = nexObj.DF_postOp.ptr.(animAx);
        aniAxis      = nexObj.DF_postOp.ax.(animAx);
        curIdx       = aPtr.value;
        winEnd_ani   = aniAxis(curIdx);
        winStart_ani = aniAxis(max(1, curIdx - len_afterImage));
    end

    % fprintf('[vis] ANI window:   %.1f ms\n', toc(t0)*1e3); t0 = tic;
    %% Subset to selected rows — all per-point work below is O(N_selected)
    mask_canvas = mask_VW & mask_ptr & mask_d1;
    G_sel  = STATE.G(mask_canvas, :);
    Z_vis  = Z_full(mask_canvas, :);
    nSel   = height(G_sel);

    % fprintf('[vis] Subset:       %.1f ms  (N_total=%d → N_sel=%d)\n', toc(t0)*1e3, height(STATE.G), nSel); t0 = tic;
    %% Color map — only over selected rows
    C_sel = zeros(nSel, 3);
    if hasClrCol
        clrVals = string(G_sel.(clrCol));
        try
            lut = nexObj.nexon.console.BASE.registry.LUT.(clrCol);
            for k = 1:height(lut)
                mask_k = clrVals == string(lut.label(k));
                hex    = char(lut.color(k));
                rgb    = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
                C_sel(mask_k, :) = repmat(rgb, sum(mask_k), 1);
            end
        catch
            uniqVals = unique(clrVals, 'stable');
            colorMap = lines(numel(uniqVals));
            for k = 1:numel(uniqVals)
                mask_k = clrVals == uniqVals(k);
                C_sel(mask_k, :) = repmat(colorMap(k,:), sum(mask_k), 1);
            end
        end
    else
        C_sel = repmat(nexObj.nexon.settings.Colors.cyberGreen, nSel, 1);
    end

    % fprintf('[vis] Color LUT:    %.1f ms\n', toc(t0)*1e3); t0 = tic;
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
    %% Tracker — per-VW-group x Per-D2 group after-image, operating on already-selected subset
    if isequal(vwGroups, ""), return; end
    activeFlds  = strrep(vwGroups, '-', '_');
    aniVals_sel = double(G_sel.(animAx));
    mask_ani    = aniVals_sel >= winStart_ani & aniVals_sel <= winEnd_ani;

    for i = 1:numel(vwGroups)
        grp = char(vwGroups(i));
        fld = char(activeFlds(i));
        if ~isfield(gfx.canvas_tracker, fld), continue; end
        if ~isvalid(gfx.canvas_tracker.(fld)), continue; end

        if hasGroupCol
            mask_grp = strcmp(G_sel.(groupCol), grp) & mask_ani;
        else
            mask_grp = mask_ani;
        end

        Z_grp = Z_vis(mask_grp, :);

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

    % fprintf('[vis] Tracker loop: %.1f ms\n', toc(t0)*1e3); t0 = tic;
    % Scrub trackers for deselected groups
    allFlds = fieldnames(gfx.canvas_tracker);
    for i = 1:numel(allFlds)
        fld = allFlds{i};
        if ~ismember(fld, activeFlds) && isvalid(gfx.canvas_tracker.(fld))
            set(gfx.canvas_tracker.(fld), 'XData', [], 'YData', [], 'ZData', []);
        end
    end
    % fprintf('[vis] Tracker scrub:%.1f ms\n', toc(t0)*1e3);
    % fprintf('[vis] TOTAL:        %.1f ms\n', toc(t_total)*1e3);
end
