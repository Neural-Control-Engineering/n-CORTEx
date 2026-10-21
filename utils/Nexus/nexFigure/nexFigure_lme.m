function nexFigure_lme(mdlObj)
% Interactive figure for mdlObj_lme. "Minimal but real" (this session's
% plan, Phase 4) -- full collector (View/Domain/Pointer) + Target, same as
% every other mdlObj, but no Save/Load UI yet and no bespoke canvas: the
% real visualizations are nexObj_violin/nexObj_monoGram, LAUNCHED from
% here via the same generic nexFigure_addLaunchControls mechanism
% nexFigure_lda.m already uses (see "Open Viewer" below) -- panel0 here is
% just a status readout, not a plot.
%
%   panel0 — status text (updated by nexFigure_lme_renderSRC, called from
%            mdlObj_lme.applySRC whenever SRC changes)
%   panel1 — sidebar (scrollable): Target / Domain / Pointer / View
%            (CTG/SWP/SRC/VW/CLR -- SWP doubles as the grid-dimension
%            selector, see nexFit_lme.m/WIP.md #12 observation 7) / Chain
%            editor / Open Viewer / Result ID / Fit chain

    BLACK = [0 0 0];
    nexon = mdlObj.nexon;
    GREEN = nexon.settings.Colors.cyberGreen;

    % ── Layout constants ──────────────────────────────────────────────────
    xRight  = 665;
    wRight  = 260;
    wInner  = 250;
    xInner  = 5;

    hBtn      = 30;
    hDomain   = 150;
    hPtr      = 150;
    hPool     = 165;
    hTarget   = 55;
    hView     = 175;
    hChain    = 120;
    hResultID = 55;
    gap       = 5;

    % Bottom-to-top y positions inside the scrollable sidebar. Standard
    % relative stacking, top-to-bottom: View, Target, Domain, Pointer --
    % View/Domain/Pointer circshifted per request (View top, Domain
    % middle, Pointer bottom), with Target kept directly below View,
    % mirroring nexFigure_lda.m's own View/Target adjacency there. No
    % separate "Grid columns" panel -- subsumed into the View panel's own
    % SWP listbox (see header comment).
    yCompile  = xInner;
    yFit      = yCompile   + hBtn      + gap;
    yResultID = yFit       + hBtn      + gap;
    yViewer   = yResultID  + hResultID + gap;
    yChain    = yViewer    + hBtn      + gap;
    yPtr      = yChain     + hChain    + gap;
    yDomain   = yPtr       + hPtr      + gap;
    yTarget   = yDomain    + hDomain   + gap;
    yView     = yTarget    + hTarget   + gap;
    yPool     = yView      + hView     + gap;   % topmost -- see Pool panel comment below

    % ── Figure ────────────────────────────────────────────────────────────
    mdlObj.Figure.fh = uifigure( ...
        "Position", [100, 500, 935, 630], ...
        "Color",    BLACK, ...
        "Name",     sprintf("LME — %s", mdlObj.dfID_source));

    % ── Canvas (left panel) — status readout only, see header comment ────
    mdlObj.Figure.panel0.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [5, 5, 655, 620], ...
        "BackgroundColor", BLACK);
    mdlObj.Figure.panel0.statusLabel = uilabel(mdlObj.Figure.panel0.ph, ...
        "Position",          [10, 580, 635, 30], ...
        "Text",              "mdlObj_lme — set a chain, then Fit chain.", ...
        "FontColor",         GREEN, ...
        "BackgroundColor",   BLACK, ...
        "Interpreter",       "none");
    mdlObj.Figure.panel0.detailArea = uitextarea(mdlObj.Figure.panel0.ph, ...
        "Position",          [10, 10, 635, 560], ...
        "Editable",          "off", ...
        "BackgroundColor",   BLACK, ...
        "FontColor",         GREEN, ...
        "FontName",          "Consolas");

    % ── Right sidebar (scrollable) ───────────────────────────────────────
    mdlObj.Figure.panel1.ph = uipanel(mdlObj.Figure.fh, ...
        "Position",        [xRight, 5, wRight, 620], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");

    % ── Target panel — Y column selector (discoverability + quantization;
    % any chain variable may be referenced regardless of this selection,
    % see mdlObj_lme.m's class header). Built HERE, not left to
    % mdlObj_lme's own constructor body -- the base mdlObject
    % constructor's figFcn(mdlObj) call (which is what runs this very
    % function) fires BEFORE control returns to mdlObj_lme's constructor,
    % so initTargetBus()/setupDomain() must be (re-)called here, same as
    % nexFigure_lda.m does at its own top. setupDomain() specifically MUST
    % run before anything below reads collector.Domain/.Pointer/.View --
    % omitting it here (an earlier bug in this file) left those buses
    % never built in the live-figure path at all, crashing at
    % buildPointerPanel()/collector.Domain.selKeys below and leaving only
    % the Target panel visible. Idempotent either way. ───────────────────
    mdlObj.initTargetBus();
    mdlObj.setupDomain();
    targetOptions = cellstr(mdlObj.collector.Target.options);
    pan_target.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yTarget, wInner, hTarget], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Target (Y)", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.targetDropdown = uidropdown(pan_target.ph, ...
        "Position",        [5, 5, wInner-70, 25], ...
        "Items",           targetOptions, ...
        "Value",           char(mdlObj.collector.Target.Y), ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ValueChangedFcn", @(src,~) nexFigure_lme_onTargetChange(src, mdlObj));
    mdlObj.Figure.targetNBinsSpinner = uispinner(pan_target.ph, ...
        "Position",        [wInner-60, 5, 55, 25], ...
        "Limits",          [2, Inf], ...
        "Value",           mdlObj.collector.Target.nBins, ...
        "Step",            1, ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "Tooltip",         "nBins — quantile groups for a continuous Target (Inf = no binning)", ...
        "ValueChangedFcn", @(src,~) nexFigure_lme_onTargetNBinsChange(src, mdlObj));

    % ── Domain + Pointer panels (collector.Domain/.Pointer built just
    % above by setupDomain(), inherited initDomainBus/initPointerBus) ────
    mdlObj.buildPointerPanel(mdlObj.Figure.panel1.ph, [xInner, yPtr, wInner, hPtr]);

    domKeys = string(fieldnames(mdlObj.collector.Domain.selKeys))';
    maxSels = zeros(1, numel(domKeys));
    for i = 1:numel(domKeys)
        k = domKeys(i);
        if k == "REG"
            maxSels(i) = 1;
        else
            maxSels(i) = numel(mdlObj.collector.Domain.selKeys.(k));
        end
    end
    pan_domain.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yDomain, wInner, hDomain], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on", ...
        "Title",           "Domain", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.panel_domain = nexObj_listCfgPanel( ...
        nexon, pan_domain, mdlObj.collector.Domain, maxSels, 10);
    for i = 1:numel(domKeys)
        k  = domKeys(i);
        lb = mdlObj.collector.Domain.listBoxes.(k);
        sel = mdlObj.collector.Domain.selections.(k);
        if ~isempty(sel) && all(sel >= 1) && all(sel <= numel(lb.String))
            lb.Value = sel;
        end
        lb.Callback = @(src, ev) nexFigure_lme_onDomainChange(src, ev, k, mdlObj);
    end

    % ── View panel — CTG / SWP / SRC / VW / CLR -- CTG is the
    % stratification mechanism (plan decision 1): select real grouping
    % columns here (e.g. "cci","side") and fitAndReport's inherited
    % fit()/fitByCombo() does the rest. SWP is the grid-dimension
    % selector (e.g. "chans","t") nexFit_lme.m reads for buildLongSTAT --
    % its established role (nexAnalysis_cvPermute.m: independent fit per
    % axis-combo, assembled into one array indexed by those axes) is
    % exactly this operation; see WIP.md #12 observation 7. ─────────────
    pan_view.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yView, wInner, hView], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on", ...
        "Title",           "View", ...
        "ForegroundColor", GREEN);
    viewMaxSels.SWP = numel(mdlObj.collector.View.selKeys.SWP);
    nex_buildCollectorViewPanel(mdlObj, pan_view.ph, hView, viewMaxSels, 10);
    bus = mdlObj.collector.View;
    bus.listBoxes.CTG.Callback = @(src,ev) nexFigure_lme_onViewChange(src, ev, 'CTG', mdlObj);
    bus.listBoxes.SWP.Callback = @(src,ev) nexFigure_lme_onViewChange(src, ev, 'SWP', mdlObj);

    % ── Chain editor — one Wilkinson formula per line (m0 first, m1,
    % m2, ...), referencing real live column names directly (plan
    % decision 4) -- "Set Chain" parses the text area into
    % defineModelChain(...) and calls mdlObj.setChain(...) ────────────────
    pan_chain.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yChain, wInner, hChain], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Chain (one formula per line, m0 first)", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.chainTextArea = uitextarea(pan_chain.ph, ...
        "Position",        [5, 30, wInner-15, hChain-55], ...
        "Value",           {'df ~ 1 + (1|sessionLabel_subj)'}, ...   % char, not string -- uitextarea's Value validator rejects a cell containing a string scalar
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "FontName",        "Consolas");
    mdlObj.Figure.setChainButton = uibutton(pan_chain.ph, ...
        "Position",        [5, 3, wInner-15, 22], ...
        "Text",            "Set Chain", ...
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN, ...
        "ButtonPushedFcn", @(~,~) nexFigure_lme_onSetChain(mdlObj));

    % ── Open Viewer controls — generic, launches nexObj_violin /
    % nexObj_monoGram the same way nexFigure_lda.m launches nexObj_bar ────
    nexFigure_addLaunchControls(mdlObj.Figure.panel1.ph, mdlObj, ...
        [xInner, yViewer, wInner, hBtn], BLACK, GREEN);

    % ── Result ID field ───────────────────────────────────────────────────
    pan_rid.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yResultID, wInner, hResultID], ...
        "BackgroundColor", BLACK, ...
        "Title",           "Result ID", ...
        "ForegroundColor", GREEN);
    mdlObj.Figure.resultIDField = uieditfield(pan_rid.ph, 'text', ...
        "Position",        [5, 5, wInner-15, 25], ...
        "Value",           'chainFit1', ...   % char, not string -- see chainTextArea note above
        "BackgroundColor", BLACK, ...
        "FontColor",       GREEN);

    % ── Fit chain button ──────────────────────────────────────────────────
    mdlObj.Figure.fitButton = uibutton(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yFit, wInner, hBtn], ...
        "Text",            "Fit chain", ...
        "BackgroundColor", GREEN, ...
        "FontColor",       BLACK, ...
        "FontWeight",      "bold", ...
        "ButtonPushedFcn", @(~,~) nexFigure_lme_fitChain(mdlObj));

    % ── Pool panel — pMap (e.g. band definitions via pMap.f, chans/t
    % windowing); pMap itself is already populated generically from
    % Origin by the base mdlObject constructor, same as every other
    % mdlObj (nothing lme-specific needed) -- this just exposes it.
    % Topmost, same reasoning as nexFigure_lda.m: a large pMap grows this
    % panel upward, and nothing above it here to overlap. ────────────────
    pan_pool.ph = uipanel(mdlObj.Figure.panel1.ph, ...
        "Position",        [xInner, yPool, wInner, hPool], ...
        "BackgroundColor", BLACK, ...
        "Scrollable",      "on");
    mdlObj.Figure.panel_pMap = nexObj_poolCfgPanel_v3( ...
        mdlObj, pan_pool, @poolCfgEntryChanged_v3);

    % ── Compile button — previously missing. Runs mdlObj.precompileSTAT(),
    % refreshing Pointer options (e.g. an epoch-pooled t axis -- Nexus
    % WIP.md #16) to the real canonical set before Fit chain, same role
    % this button plays in nexFigure_lda/_pca/_ssm. Bottommost, same
    % convention as those three.
    mdlObj.Figure.compileButton = nexFigure_addCompileControl( ...
        mdlObj.Figure.panel1.ph, mdlObj, [xInner, yCompile, wInner, hBtn], BLACK, GREEN);
end


% ── Local callbacks ───────────────────────────────────────────────────────

function nexFigure_lme_onTargetChange(src, mdlObj)
    mdlObj.collector.Target.Y = src.Value;
    mdlObj.applyTargetBus();
end

function nexFigure_lme_onTargetNBinsChange(src, mdlObj)
    mdlObj.collector.Target.nBins = src.Value;
end

function nexFigure_lme_onDomainChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, char(key), mdlObj.collector.Domain);
    mdlObj.applyDomainBus();
    if key == "FTR"
        mdlObj.refreshREG();
    end
end

function nexFigure_lme_onViewChange(src, ev, key, mdlObj)
    listCfgEntryChanged(src, ev, key, mdlObj.collector.View);
    mdlObj.applyViewBus();   % syncs domain.CTG/domain.SWP from the bus selection
end

function nexFigure_lme_onSetChain(mdlObj)
% Each non-empty line of the chain text area is one Wilkinson formula,
% in step order (line 1 = m0, line 2 = m1, ...) -- straight into
% defineModelChain.m, same as calling it by hand. See mdlObj_lme.m's
% class header for a full worked example of the resulting chain struct.
    lines = mdlObj.Figure.chainTextArea.Value;
    lines = lines(strlength(strtrim(string(lines))) > 0);
    if isempty(lines)
        fprintf('[nexFigure_lme] chain text area is empty -- nothing set.\n');
        return;
    end
    chain = defineModelChain(cellstr(lines));
    mdlObj.setChain(chain);
    fprintf('[nexFigure_lme] chain set: %s (variables: %s)\n', ...
        strjoin([chain.steps.step], ', '), strjoin(chain.variables, ', '));
end

function nexFigure_lme_fitChain(mdlObj)
    resultID = strtrim(mdlObj.Figure.resultIDField.Value);
    if isempty(resultID), resultID = sprintf('chainFit_%s', char(datetime('now','Format','HHmmss'))); end
    try
        mdlObj.fitAndReport(resultID);
    catch ME
        mdlObj.Figure.panel0.statusLabel.Text = sprintf('Fit failed: %s', ME.message);
        disp(getReport(ME));
    end
end

function nexFigure_lme_renderSRC(mdlObj, srcKey)
% mdlObj_lme.applySRC's render hook (called in a try/catch there, so this
% function not existing yet is harmless pre-Phase-4) -- updates panel0's
% status readout with the selected RESULTS row's grid shape, nothing more
% elaborate (the real visualizations are nexObj_violin/nexObj_monoGram,
% launched separately via "Open Viewer" above).
    if ~isfield(mdlObj.Figure, 'panel0'), return; end
    srcKey = char(srcKey);
    if strcmp(srcKey, 'fit')
        mdlObj.Figure.panel0.statusLabel.Text = 'mdlObj_lme — set a chain, then Fit chain.';
        mdlObj.Figure.panel0.detailArea.Value = {};
        return;
    end
    if ~isfield(mdlObj.RESULTS, srcKey)
        return;
    end
    R = mdlObj.RESULTS.(srcKey);
    mdlObj.Figure.panel0.statusLabel.Text = sprintf('SRC = %s  (%d row(s))', srcKey, height(R));
    lines = strings(height(R), 1);
    for ri = 1:height(R)
        axFields = fieldnames(R.ax{ri});
        dims = strings(1, numel(axFields));
        for ai = 1:numel(axFields)
            dims(ai) = sprintf('%s=%d', axFields{ai}, numel(R.ax{ri}.(axFields{ai})));
        end
        keyCols = setdiff(string(R.Properties.VariableNames), ["df","ax","ptr"], 'stable');
        keyStr  = "";
        for ki = 1:numel(keyCols)
            keyStr = keyStr + sprintf('%s=%s ', keyCols(ki), string(R.(char(keyCols(ki)))(ri)));
        end
        lines(ri) = sprintf('row %d: %s | df %s | %s', ri, keyStr, mat2str(size(R.df{ri})), strjoin(dims, ', '));
    end
    mdlObj.Figure.panel0.detailArea.Value = cellstr(lines);
end
