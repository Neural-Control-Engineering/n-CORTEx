classdef nexObj_fitScope < nexObject
% Interactive hand-tuning tool for spectral-parameterization labels.
%
% Reads a raw PSD volume (dfID_source, e.g. an rtPMTM patch) plus two
% EXISTING fit-parameter volumes if present (dfID_ap/dfID_pe, e.g.
% specparam_ap_winX/specparam_pe_winX — nexFit_specParam's own DF_ap/DF_pe
% shape: (chans,t,7) and (chans,t,maxPeaks,3)) for the current trial (the
% active router selection). Channel/time navigation is a real
% collector.Pointer bus (chans, t — f excluded, see initPointerBus), same
% mechanism/panel every other nexObject uses, instead of the original
% bespoke uispinner pair. At the current Pointer position, the AP/PE slice
% is merged into one kernel_args struct (spcpmIO_apPe2kernel) driving
% kernel_specparam_segmented_multiexp's live overlay AND the auto-built
% spinner panel (nexObj_cfgPanel_spinner — kernel-agnostic, unchanged).
% "Regenerate" runs specParam_multiExp fresh on just the current slice's
% raw PSD as a starting point to hand-tune from. "Save" writes the tuned
% slice out as a NEW sibling patch (dfID_output-derived names,
% "specparam_ap_"/"specparam_pe_" + a user-typed label) — never back into
% dfID_ap/dfID_pe themselves — cloning/updating that output patch's
% existing trial volume if one already exists (so multiple saves across
% different chan/t positions accumulate into one full-trial volume), or
% seeding a NaN volume from dfID_source's chan/t axes otherwise.
%
% Modernized from the original bespoke `< handle` version: now a real
% nexObject subclass (applyHeadline/closeFcn/registry inherited, Pointer
% bus for chan/t navigation instead of raw uispinners), reads via
% dtsIO_readDF/writeDF like every other patch-based Nexus consumer
% instead of taking a DF handed in directly, and drives
% kernel_specparam_segmented_multiexp (matching specParam_multiExp's
% actual current output shape) instead of the older, mismatched
% kernel_specparam_skewed_multiexp.
%
% Redraw entry points (kept deliberately separate — see each method):
%   visualize()   — Pointer bus (chan/t) navigation: re-slice from disk
%                   at the new position, THEN redraw.
%   updateScope() — spinner-panel edits (fitCfg.entryParams changed by
%                   hand): redraw only, never re-slice — a re-slice here
%                   would silently discard the user's in-progress edit.
%   redraw()      — shared drawing step both of the above end in.

    properties
        dfID_ap               % existing AP fit patch to read (may not exist yet)
        dfID_pe               % existing PE fit patch to read (may not exist yet)
        lastOutputLabel = ""  % user-typed stem for the NEW output patch —
                               % "specparam_ap_"+this, "specparam_pe_"+this
        dtsIdx                 % current trial's DTS row index (active router selection)
        DF_ap                   % existing AP volume for this trial (or [])
        DF_pe                   % existing PE volume for this trial (or [])
        fitCfg                  % .kernel (function handle), .entryParams (live-edited kernel_args struct)
        maxPeaks = 24            % PE row count per slice — numPeaks_max*3segments, matches nexFit_specParam
    end

    methods
        function nexObj = nexObj_fitScope(Parent, dfID_source, dfID_ap, dfID_pe)
            nexon = Parent.nexon;
            nexObj = nexObj@nexObject(nexon, Parent, dfID_source, ...
                sprintf("FitScope — %s", dfID_source));
            nexObj.classID = "fitScp";
            nexObj.dfID_ap = string(dfID_ap);
            nexObj.dfID_pe = string(dfID_pe);

            nexObj.dtsIdx = find(nex_getRouterIdx(nexon), 1);
            if isempty(nexObj.dtsIdx)
                error('nexObj_fitScope:noActiveTrial', ...
                    ['No trial matches the current router selection — pick a ' ...
                     'session/trial before opening FitScope.']);
            end

            nexObj.fitCfg.kernel = @kernel_specparam_segmented_multiexp;

            nexObj.loadTrial();       % DF_postOp (raw PSD) + DF_ap/DF_pe for dtsIdx
            nexObj.initPointerBus();  % collector.Pointer: chans, t (f excluded)
            nexObj.readSlice();       % seeds fitCfg.entryParams from the current Pointer position

            isHeadless = isfield(nexon, 'settings') && isfield(nexon.settings, 'headless') ...
                         && nexon.settings.headless;
            if ~isHeadless
                nexFigure_fitScope(nexObj);
                nexObj.applyHeadline();
                nexRegister_figure(nexon, nexObj);
            end
        end

        function loadTrial(nexObj)
        % Read the raw PSD volume + whatever AP/PE fit volumes already
        % exist for the current trial (dtsIdx). Missing AP/PE patches are
        % expected (nothing fit yet there) — caught, not surfaced as errors.
            DF = dtsIO_readDF(nexObj.nexon, nexObj.dfID_source, nexObj.dtsIdx);
            nexObj.DF_postOp = nex_initAxisPointer_v2(DF);   % .ptr.(axis) = {dim,value,range,window}, nexObj_ptr-wrapped

            try
                nexObj.DF_ap = dtsIO_readDF(nexObj.nexon, nexObj.dfID_ap, nexObj.dtsIdx);
            catch
                nexObj.DF_ap = [];
            end
            try
                nexObj.DF_pe = dtsIO_readDF(nexObj.nexon, nexObj.dfID_pe, nexObj.dtsIdx);
            catch
                nexObj.DF_pe = [];
            end
        end

        function initPointerBus(nexObj)
        % Override of the base nexObject.initPointerBus: that one builds
        % one Pointer key per DF_postOp.ax field, which would include 'f'
        % — the whole plotted spectrum, not something to "visit one value
        % of". Scoped to chans/t only.
            ptrDict.chans = nexObj.DF_postOp.ax.chans;
            ptrDict.t     = nexObj.DF_postOp.ax.t;
            nexObj.collector.Pointer = buildSelection(nexObj, ptrDict);
        end

        function [ptr_chans, ptr_t] = currentPtr(nexObj)
        % Current chan/t POSITION indices (into DF_postOp.ax.chans/.t) —
        % listCfgEntryChanged's generic Pointer-callback writes the
        % selected listbox position into ptr.(key).value on every
        % navigation (see class header).
            ptr_chans = nexObj.DF_postOp.ptr.chans.value;
            ptr_t     = nexObj.DF_postOp.ptr.t.value;
        end

        function readSlice(nexObj)
        % Seed fitCfg.entryParams from the current chan/t Pointer position
        % — the existing AP/PE fit there if the read-target patches have
        % one, otherwise the kernel's own bare defaults (extractMethodCfg).
            [ptr_chans, ptr_t] = nexObj.currentPtr();
            chanVal = nexObj.DF_postOp.ax.chans(ptr_chans);
            tVal    = nexObj.DF_postOp.ax.t(ptr_t);

            apRow = [];
            peMat = [];
            try
                ci    = find(nexObj.DF_ap.ax.chans == chanVal, 1);
                ti    = find(nexObj.DF_ap.ax.t     == tVal,    1);
                apRow = squeeze(nexObj.DF_ap.df(ci, ti, :))';
            catch
            end
            try
                ci    = find(nexObj.DF_pe.ax.chans == chanVal, 1);
                ti    = find(nexObj.DF_pe.ax.t     == tVal,    1);
                peMat = squeeze(nexObj.DF_pe.df(ci, ti, :, :));
            catch
            end

            if ~isempty(apRow) && all(~isnan(apRow))
                nexObj.fitCfg.entryParams = spcpmIO_apPe2kernel(apRow, peMat);
            else
                nexObj.fitCfg.entryParams = extractMethodCfg('kernel_specparam_segmented_multiexp');
            end
            nexObj.fitCfg.entryParams = nexObj.padPeakSlots(nexObj.fitCfg.entryParams);
        end

        function ep = padPeakSlots(nexObj, ep)
        % Ensure OFF/EXP1-3/FC1-3 + exactly maxPeaks CF/PW/BW triplets are
        % ALWAYS present, zero-filled where a real peak doesn't already
        % exist. Needed because the spinner panel is built once, from
        % whatever fields entryParams happens to have at that moment —
        % alignEntryParams only updates spinners that already exist, so a
        % variable/short field set here means some peaks silently never
        % get a control (this is what was actually missing: the kernel's
        % own extractMethodCfg defaults don't include ANY CF/PW/BW fields
        % at all — they're commented out in its CFG HEADER — and a real
        % fit's own peak count varies run to run). 0, not NaN, is the
        % "empty slot" sentinel here to match formatSpecParamOutputs'
        % own zero-padding convention for this same flat-vector level of
        % the pipeline (nexFit_specParam's AP/PE *volumes* use NaN for
        % "no data at all for this slice" — a different, higher level).
        % saveFit's df_fit format writes every slot verbatim (named via
        % ax_fit.param), zero-padding included — no compaction/filtering
        % needed there since each slot is self-describing, and PW=0
        % already contributes nothing in the kernel's own reconstruction.
            base = ["OFF", "EXP1", "EXP2", "EXP3", "FC1", "FC2", "FC3"];
            for i = 1:numel(base)
                if ~isfield(ep, base(i)), ep.(base(i)) = 0; end
            end
            for p = 1:nexObj.maxPeaks
                for pre = ["CF", "PW", "BW"]
                    fld = sprintf("%s%d", pre, p);
                    if ~isfield(ep, fld), ep.(fld) = 0; end
                end
            end
        end

        function visualize(nexObj)
        % Pointer bus (chan/t) navigation entry point — redraw only, same
        % as updateScope. Deliberately does NOT re-slice from disk:
        % fitCfg.entryParams is the user's hand-tuned working state, and
        % should survive moving to a different chan/t to compare against
        % (the raw signal/context traces update to the new position; the
        % fit overlay stays whatever was last tuned). readSlice() is still
        % used once at construction to seed from an existing fit if there
        % is one — use Regenerate to explicitly re-fit the new position
        % from scratch instead.
            nexObj.redraw();
        end

        function updateScope(nexObj)
        % Spinner-panel entry point (cfgEntryChanged, on every hand-tuned
        % parameter edit) — redraw only, never re-slice. Re-slicing here
        % would silently overwrite the edit that just triggered this call.
            nexObj.redraw();
        end

        function redraw(nexObj)
            if isempty(nexObj.Figure) || ~isfield(nexObj.Figure, 'panel1'), return; end
            nexObj.DF_postOp.df_fit = nexObj.fitCfg.kernel(nexObj.DF_postOp.ax, nexObj.fitCfg.entryParams);
            % Aperiodic-only curve (peaks zeroed via the same helper the
            % null-peaks toggle uses) — a second overlay so the aperiodic
            % shape and the full periodic+aperiodic fit stay visually
            % distinguishable without having to toggle null-peaks back
            % and forth.
            nexObj.DF_postOp.df_fit_ap = nexObj.fitCfg.kernel(nexObj.DF_postOp.ax, ...
                spcpmIO_nullifyPeaks(nexObj.fitCfg.entryParams));
            nexVisualization_fitScope(nexObj, struct);
        end

        function [f_psd, df_psd] = currentRawPSD(nexObj)
        % Raw PSD (f, power) for the CURRENT chan/t Pointer position —
        % shared by fitAperiodic/fitPeriodic's own on-demand, single-slice
        % calls into specParam_multiExp.
            [ptr_chans, ptr_t] = nexObj.currentPtr();
            f_psd  = nexObj.DF_postOp.ax.f;
            % (:)' — not just ' — guarantees a proper row vector regardless
            % of what shape squeeze leaves behind; same defensive pattern
            % nexFit_specParam itself uses before calling specParam_multiExp,
            % which internally horzcats per-segment slices and needs every
            % row-vector call to actually BE a row, or that horzcat breaks.
            df_psd = squeeze(nexObj.DF_postOp.df(ptr_chans, :, ptr_t));
            df_psd = df_psd(:)';
        end

        function regenerateFit(nexObj)
        % "Fit": one-shot full re-fit — auto-detect corner frequencies and
        % fit multi-exp on the CURRENT chan/t slice's raw PSD from
        % scratch, replacing BOTH the aperiodic (OFF/EXP1-3/FC1-3) AND
        % peak (CF*/PW*/BW*) params wholesale. Kept alongside the split
        % fitAperiodic/fitPeriodic pair for when a full from-scratch fit
        % is what's actually wanted, rather than refining one half only.
            [f_psd, df_psd] = nexObj.currentRawPSD();
            spcpmArgs = extractMethodCfg('specParam_multiExp');
            [~, kernel_args] = specParam_multiExp(f_psd, df_psd, spcpmArgs);
            nexObj.fitCfg.entryParams = nexObj.padPeakSlots(kernel_args);
            nexObj.alignEntryParams();
            nexObj.redraw();
        end

        function fitAperiodic(nexObj)
        % "Fit_ap": auto-detect corner frequencies + fit multi-exp on the
        % CURRENT chan/t slice's raw PSD from scratch (on-demand, single-
        % slice — same as the original Regenerate), but ONLY update
        % OFF/EXP1-3/FC1-3 — whatever peaks (CF*/PW*/BW*) are already in
        % entryParams (hand-tuned or from a prior Fit_pe) are left as-is.
            [f_psd, df_psd] = nexObj.currentRawPSD();
            spcpmArgs = extractMethodCfg('specParam_multiExp');
            [~, kernel_args] = specParam_multiExp(f_psd, df_psd, spcpmArgs);
            apFields = ["OFF", "EXP1", "EXP2", "EXP3", "FC1", "FC2", "FC3"];
            for i = 1:numel(apFields)
                nexObj.fitCfg.entryParams.(apFields(i)) = kernel_args.(apFields(i));
            end
            nexObj.fitCfg.entryParams = nexObj.padPeakSlots(nexObj.fitCfg.entryParams);
            nexObj.alignEntryParams();
            nexObj.redraw();
        end

        function fitPeriodic(nexObj)
        % "Fit_pe": use the EXISTING FC2/FC3 (current entryParams — NOT
        % re-detected) to re-segment the spectrum and fit multi-exp, but
        % ONLY update the peaks (CF*/PW*/BW*) — OFF/EXP1-3/FC1-3 are left
        % as-is. FC2/FC3, not FC1, are the real segment-boundary corners
        % here (FC1 is just fRange_start — see spcpmIO_multiSpecs2vector);
        % specParam_multiExp appends f_psd(end) itself to complete the
        % (up to) 3-segment split.
            [f_psd, df_psd] = nexObj.currentRawPSD();
            spcpmArgs   = extractMethodCfg('specParam_multiExp');
            ep          = nexObj.padPeakSlots(nexObj.fitCfg.entryParams);
            % Clamp into the actual data range and sort ascending before
            % reuse — FC2/FC3 may still be the kernel's bare placeholder
            % defaults (e.g. FC3=250) if no real AP fit has run yet on
            % this slice, and specParam_multiExp never checks a corner
            % against the data's own extent — an out-of-range or
            % inverted boundary here silently produces an empty segment,
            % which Python's specparam rejects with an opaque dimension
            % error rather than anything actionable.
            cornerFreqs = sort(min(max([ep.FC2, ep.FC3], f_psd(1)), f_psd(end)));
            [~, kernel_args] = specParam_multiExp(f_psd, df_psd, spcpmArgs, cornerFreqs);

            % Clear every existing peak slot first — the new fit's peak
            % count may be smaller than what was there before, and any
            % slot the new fit doesn't touch below needs to fall back to
            % "empty" (0), not linger at its old (now stale) value.
            for p = 1:nexObj.maxPeaks
                for pre = ["CF", "PW", "BW"]
                    ep.(sprintf("%s%d", pre, p)) = 0;
                end
            end
            peakFields = string(fieldnames(kernel_args));
            peakFields = peakFields(startsWith(peakFields, "CF") | ...
                                     startsWith(peakFields, "PW") | ...
                                     startsWith(peakFields, "BW"));
            for i = 1:numel(peakFields)
                ep.(peakFields(i)) = kernel_args.(peakFields(i));
            end
            nexObj.fitCfg.entryParams = nexObj.padPeakSlots(ep);
            nexObj.alignEntryParams();
            nexObj.redraw();
        end

        function nullifyPeaks(nexObj, src, event) %#ok<INUSD>
        % Toggle peaks off/on to isolate the aperiodic curve while tuning.
            if ~isfield(nexObj.UserData, 'toggle') || ~isfield(nexObj.UserData.toggle, 'nullifyPeaks')
                nexObj.UserData.toggle.nullifyPeaks = false;
            end
            if ~nexObj.UserData.toggle.nullifyPeaks
                nexObj.UserData.savedEntryParams  = nexObj.fitCfg.entryParams;
                nexObj.fitCfg.entryParams         = spcpmIO_nullifyPeaks(nexObj.fitCfg.entryParams);
                nexObj.UserData.toggle.nullifyPeaks = true;
                nexObj.Figure.nullPeaksButton.BackgroundColor = nexObj.nexon.settings.Colors.disableGrey;
            else
                nexObj.fitCfg.entryParams = nexObj.UserData.savedEntryParams;
                nexObj.UserData.toggle.nullifyPeaks = false;
                nexObj.Figure.nullPeaksButton.BackgroundColor = nexObj.nexon.settings.Colors.activeGrey;
            end
            nexObj.alignEntryParams();
            nexObj.redraw();
        end

        function alignEntryParams(nexObj)
            panFields = fieldnames(nexObj.Figure.panel2.editFields);
            for i = 1:numel(panFields)
                f = panFields{i};
                if isfield(nexObj.fitCfg.entryParams, f)
                    nexObj.Figure.panel2.editFields.(f).uiField.Value = nexObj.fitCfg.entryParams.(f);
                end
            end
        end

        function saveFit(nexObj, src, event) %#ok<INUSD>
        % Write the current (chan,t) slice's hand-tuned fit into ONE
        % self-contained, shareable sibling patch — never back into
        % dfID_ap/dfID_pe. The patch bundles:
        %   df/ax       — the RAW PSD, the full trial volume (copied in
        %                 wholesale, not just this slice) so a peer never
        %                 needs the original source patch.
        %   df_fit      — (chans, t, nParams), index-ALIGNED to df/ax's
        %                 own chans/t (same values, same order) so a given
        %                 slot's fit is unambiguous relative to the PSD it
        %                 was fit from, and un-fit slots simply stay NaN,
        %                 ready to be filled in by a later save.
        %   ax_fit      — .chans/.t mirror df/ax's own (shared domain);
        %                 .param names df_fit's trailing dimension, in
        %                 spcpmIO_paramNames' fixed order.
        %   kernel      — .fcn (function NAME, not a handle — handles
        %                 don't round-trip through HDF5), .maxPeaks,
        %                 .fitArgs — everything nexObj_fitScope (or a
        %                 peer's own copy) needs to reconstruct the PSD
        %                 from df_fit's params with no other context.
        % Read-before-write: an existing patch for this label is loaded
        % and only the current slot updated, so repeated saves — today,
        % or reopening this same label in a later session — accumulate
        % into one growing patch instead of clobbering each other.
            label = regexprep(strtrim(char(nexObj.lastOutputLabel)), '[^a-zA-Z0-9_]', '_');
            if isempty(label)
                fprintf('[nexObj_fitScope] saveFit: type an output label first (dfID_output field) — nothing saved.\n');
                return;
            end
            dfID_out = "specparam_" + label;

            nexObj.fitCfg.entryParams = spcpmIO_sortFitParams(nexObj.fitCfg.entryParams);
            nexObj.alignEntryParams();

            paramNames = spcpmIO_paramNames(nexObj.maxPeaks);
            DF_out     = nexObj.loadOrSeedFitPatch(dfID_out, paramNames);

            [ptr_chans, ptr_t] = nexObj.currentPtr();
            fitVec = spcpmIO_kernel2vector(nexObj.fitCfg.entryParams, paramNames);
            DF_out.df_fit(ptr_chans, ptr_t, :) = reshape(fitVec, 1, 1, []);

            nexObj.writePatch(dfID_out, DF_out);
            fprintf('[nexObj_fitScope] saved chan=%s t=%s -> %s\n', ...
                    string(nexObj.DF_postOp.ax.chans(ptr_chans)), ...
                    string(nexObj.DF_postOp.ax.t(ptr_t)), dfID_out);
        end

        function DF_out = loadOrSeedFitPatch(nexObj, dfID_out, paramNames)
        % Read an existing unified fit patch for this trial if one already
        % exists (from an earlier save, possibly a prior session), else
        % seed a fresh one: the FULL raw PSD volume (already fully known,
        % copied as-is) + an empty (NaN) df_fit volume aligned to it.
            try
                DF_out = dtsIO_readDF(nexObj.nexon, dfID_out, nexObj.dtsIdx);
                if isfield(DF_out, 'df_fit') && ~isempty(DF_out.df_fit)
                    return;
                end
            catch
            end
            DF_out.df = nexObj.DF_postOp.df;
            DF_out.ax = nexObj.DF_postOp.ax;

            nChan = numel(nexObj.DF_postOp.ax.chans);
            nTime = numel(nexObj.DF_postOp.ax.t);
            DF_out.df_fit       = nan(nChan, nTime, numel(paramNames));
            DF_out.ax_fit.chans = nexObj.DF_postOp.ax.chans;
            DF_out.ax_fit.t     = nexObj.DF_postOp.ax.t;
            DF_out.ax_fit.param = paramNames;

            DF_out.kernel.fcn      = func2str(nexObj.fitCfg.kernel);
            DF_out.kernel.maxPeaks = nexObj.maxPeaks;
            DF_out.kernel.fitArgs  = extractMethodCfg('specParam_multiExp');
        end

        function writePatch(nexObj, dfID_out, DF_out)
        % Write DF_out as a sibling patch h5 file for the current trial —
        % same pattern mdlObject.scaleApply_transform uses: a dedicated
        % <base>_<dfID>.h5 file, never the shared base DTS file, so this
        % never needs write access to (or risks corrupting) the main
        % manifest.
            nexon = nexObj.nexon;
            isDiskBacked = ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames);
            if isDiskBacked
                allH5 = string(nexon.console.BASE.DTS.h5_path);
                [pd, pb, pe] = fileparts(char(allH5(nexObj.dtsIdx)));
                h5FileOut = fullfile(pd, [pb '_' char(dfID_out) pe]);
                dtsIO_patchManifest(nexon, dfID_out, h5FileOut);
                h5Root = char(nexon.console.BASE.DTS.h5_root(nexObj.dtsIdx));
                dtsIO_writeDF_toHDF5(h5FileOut, h5Root, char(dfID_out), DF_out);
            else
                dtsIO_patchManifest(nexon, dfID_out, []);
                dtsIO_writeDF(nexon, DF_out, dfID_out, nexObj.dtsIdx);
            end
        end
    end
end
