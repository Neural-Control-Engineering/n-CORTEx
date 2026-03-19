function nexVisualization_stateSpace(nexObj, ~)
    % Data-tier update: only set() on existing handles.  Never creates or
    % deletes scatter3 objects — that is rebuildTrackers()'s job.

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

    %% Factor column indices (X / Y / Z of scatter3)
    % Read directly from the Domain selectionBus — domain.F is not consulted.
    domSel = nex_returnSelectionMask(nexObj.collector.Domain);
    fSel   = string(domSel.F);
    d1Ax   = char(domSel.D1);
    animAx = char(nexObj.domain.animate);
    if isempty(fSel) || isequal(fSel, ""), return; end

    if ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ax') ...
            && isfield(nexObj.DF_postOp.ax, 'factor')
        factorList = string(nexObj.DF_postOp.ax.factor);
    else
        factorList = "f" + string(1:size(STATE.Z, 2));
    end
    [~, fIdx] = ismember(fSel, factorList);
    fIdx = fIdx(fIdx > 0);
    if numel(fIdx) < 2, return; end

    % Pad to 3 columns with zeros when only 2 factors are selected
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

    %% VW row mask
    if hasGroupCol && ~isequal(vwGroups, "")
        mask_VW = ismember(string(STATE.G.(groupCol)), vwGroups);
    else
        mask_VW = true(height(STATE.G), 1);
    end

    %% Pointer mask — restrict rows to selected axis values.
    % STATE.G has axis value columns (t, ch, f, ...) added by buildSTATE.
    % For each Pointer axis, keep only rows whose axis value is selected.
    mask_ptr = true(height(STATE.G), 1);
    if ~isempty(nexObj.collector.Pointer)
        ptrSel  = nex_returnSelectionMask(nexObj.collector.Pointer);
        ptrAxes = fieldnames(ptrSel);
        for k = 1:numel(ptrAxes)
            f   = ptrAxes{k};
            sel = ptrSel.(f);
            if ~isempty(sel) && ~isequal(sel, "") && ismember(f, gCols)
                gVals    = round(double(STATE.G.(f)),   6, 'significant');
                selVals  = round(double(sel),           6, 'significant');
                mask_ptr = mask_ptr & ismember(gVals, selVals);
            end
        end
    end
    mask_canvas = mask_VW & mask_ptr;

    %% D1 context window — sliding window along D1 axis driven by DF_postOp.ptr.
    % ptr.(d1Ax).window defines how many D1 slices remain in view;
    % ptr.(d1Ax).value is the current leading edge.
    if ~isempty(d1Ax) && ismember(d1Ax, gCols) ...
            && ~isempty(nexObj.DF_postOp) && isprop(nexObj.DF_postOp, 'ptr') ...
            && isprop(nexObj.DF_postOp.ptr, d1Ax) && isfield(nexObj.DF_postOp.ax, d1Ax)
        d1Ptr    = nexObj.DF_postOp.ptr.(d1Ax);
        d1Axis   = nexObj.DF_postOp.ax.(d1Ax);
        curIdx   = d1Ptr.value;
        half     = round(d1Ptr.window / 2);
        startIdx = max(1, curIdx - half);
        endIdx   = min(numel(d1Axis), curIdx + half);
        d1Start  = d1Axis(startIdx);
        d1End    = d1Axis(endIdx);
        d1Vals_G = double(STATE.G.(d1Ax));
        mask_canvas = mask_canvas & d1Vals_G >= d1Start & d1Vals_G <= d1End;
    end

    %% ANI pointer + after-image length — governs tracker window.
    % len_afterImage: how many ANI steps the tracker trails behind curANI.
    len_afterImage = 5;   % default
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
        aPtr       = nexObj.DF_postOp.ptr.(animAx);
        aniAxis    = nexObj.DF_postOp.ax.(animAx);
        curIdx     = aPtr.value;
        startIdx   = max(1, curIdx - len_afterImage);
        winEnd_ani   = aniAxis(curIdx);
        winStart_ani = aniAxis(startIdx);
    end

    %% Color map — registry LUT if available, else auto-assign via lines()
    C_all = zeros(height(STATE.G), 3);
    if hasClrCol
        clrVals = string(STATE.G.(clrCol));
        try
            lut = nexObj.nexon.console.BASE.registry.LUT.(clrCol);
            for k = 1:height(lut)
                mask_k = clrVals == string(lut.label(k));
                hex    = char(lut.color(k));
                rgb    = [hex2dec(hex(1:2)), hex2dec(hex(3:4)), hex2dec(hex(5:6))] / 255;
                C_all(mask_k, :) = repmat(rgb, sum(mask_k), 1);
            end
        catch
            % Fallback: auto-assign one color per unique value via lines()
            uniqVals = unique(clrVals, 'stable');
            colorMap = lines(numel(uniqVals));
            for k = 1:numel(uniqVals)
                mask_k = clrVals == uniqVals(k);
                C_all(mask_k, :) = repmat(colorMap(k,:), sum(mask_k), 1);
            end
        end
    else
        C_all = repmat(nexObj.nexon.settings.Colors.cyberGreen, height(STATE.G), 1);
    end

    %% D1 brightness gradient — darker at low D1 values, brighter at high.
    % Base group color (from CLR) is preserved; only luminance is modulated.
    if ~isempty(d1Ax) && ismember(d1Ax, STATE.G.Properties.VariableNames)
        d1Vals  = double(STATE.G.(d1Ax));
        d1Min   = min(d1Vals(mask_canvas));   % normalize to visible sub-selection
        d1Max   = max(d1Vals(mask_canvas));
        if d1Max > d1Min
            minBright  = 0.15;
            brightness = minBright + (1 - minBright) * (d1Vals - d1Min) / (d1Max - d1Min);
            brightness = max(minBright, min(1.0, brightness));  % clamp out-of-range rows
            C_all      = C_all .* brightness;
        end
    end

    %% Scatter size — scale linearly with divsPerBin of the animated axis.
    % More samples pooled per bin → each point represents more data → larger dot.
    canvasSize  = 100;
    trackerSize = 150;
    if ~isempty(animAx) && ~isempty(nexObj.pMap) && isfield(nexObj.pMap, animAx)
        dpb = nexObj.pMap.(animAx).divsPerBin;
        if dpb > 1
            canvasSize  = canvasSize  * dpb;
            trackerSize = trackerSize * dpb;
        end
    end

    %% Canvas — VW + Pointer filtered point cloud
    Z_vis = Z_full(mask_canvas, :);
    C_vis = C_all(mask_canvas, :);
    set(gfx.canvas, ...
        'XData',    Z_vis(:,1), ...
        'YData',    Z_vis(:,2), ...
        'ZData',    Z_vis(:,3), ...
        'CData',    C_vis, ...
        'SizeData', canvasSize);

    % Axis labels
    ax.XLabel.String = char(fSel(1));
    ax.YLabel.String = char(fSel(2));
    if numel(fIdx) >= 3, ax.ZLabel.String = char(fSel(3)); end

    %% Tracker — per-VW-group after-image along ANI axis
    % Color: boost HSV saturation and value to max so tracker sits vivid
    % on top of the dimmed canvas, regardless of which CLR hue is in use.
    if isequal(vwGroups, ""), return; end
    activeFlds = strrep(vwGroups, '-', '_');
    aniVals_G  = double(STATE.G.(animAx));
    for i = 1:numel(vwGroups)
        grp = char(vwGroups(i));
        fld = char(activeFlds(i));
        if ~isfield(gfx.canvas_tracker, fld), continue; end
        if ~isvalid(gfx.canvas_tracker.(fld)), continue; end

        if hasGroupCol
            mask_grp = ismember(string(STATE.G.(groupCol)), grp) ...
                     & aniVals_G >= winStart_ani & aniVals_G <= winEnd_ani;
        else
            mask_grp = aniVals_G >= winStart_ani & aniVals_G <= winEnd_ani;
        end

        Z_grp = Z_full(mask_grp, :);

        % Vivify: convert to HSV, push S→1 and V→1, back to RGB
        hsv_grp       = rgb2hsv(C_all(mask_grp, :));
        hsv_grp(:, 2) = 1.0;   % full saturation
        hsv_grp(:, 3) = 1.0;   % full brightness
        try
            C_grp_vivid   = hsv2rgb(hsv_grp);
        catch
            return
        end

        set(gfx.canvas_tracker.(fld), ...
            'XData',    Z_grp(:,1), ...
            'YData',    Z_grp(:,2), ...
            'ZData',    Z_grp(:,3), ...
            'CData',    C_grp_vivid, ...
            'SizeData', trackerSize);
    end
end
