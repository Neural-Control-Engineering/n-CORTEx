function [TF_aligned, canonReg, ftrAxis] = nexOp_alignCoAxes(TF, regAxis, poolFn, canonRegOverride)
% Canonicalize a co-registered FTR axis across all DFs in TF.
%
% THE PROBLEM THIS SOLVES
% ------------------------
% Different sessions/trials record different, only partially-overlapping
% sets of units/channels. You can't just stack their DFs into one array —
% "position 3" means unit 12 in session A and unit 47 in session B. Before
% anything can be pooled, averaged, or fed into a model across sessions,
% every DF needs to agree on what each position along the feature axis
% *means*. This function forces that agreement: it builds one canonical,
% ordered list of REG identities (the union across every DF) and reslots
% each DF's data into that shared layout — inserting NaN wherever a DF
% never recorded a given identity, since "never recorded" and "recorded
% and happened to be zero" are different facts that must not be conflated.
%
% RUNNING EXAMPLE (referenced throughout this file's comments)
% --------------------------------------------------------------
%   DF_A.ax.unit = [10 20 30]        (session A recorded these 3 units)
%   DF_B.ax.unit = [20 30 40 50]     (session B recorded these 4 units)
%   regAxis = 'unit'
%
%   Canonical union (sorted):  [10 20 30 40 50]   → nCanon = 5
%
%   After alignment:
%   DF_A.df reslotted to 5 canonical positions:
%     [10]->real, [20]->real, [30]->real, [40]->NaN, [50]->NaN
%   DF_B.df reslotted to 5 canonical positions:
%     [10]->NaN,  [20]->real, [30]->real, [40]->real, [50]->real
%
%   Now DF_A.df and DF_B.df have the SAME shape along the FTR dimension,
%   and position k means the same canonical unit in both — they can be
%   concatenated, averaged, or stacked into one design matrix.
%
% THE THREE CASES PER CANONICAL VALUE, PER DF (see the main loop below)
% -----------------------------------------------------------------------
%   0 matching positions  → this DF never recorded that identity.
%                            NaN-fill (0-fill if df isn't float, since NaN
%                            isn't representable for ints/logicals) — kept
%                            distinct from a real zero-valued measurement
%                            so downstream pooling/cropping can tell
%                            "absent" from "present but zero" apart.
%                            pm.pool() already averages with 'omitnan', so
%                            NaN-filled positions don't bias a pooled mean.
%                            Any NaN still standing once a design matrix is
%                            built must be resolved (e.g. zero-filled) by
%                            the caller — no fit function here handles NaN.
%   1 matching position   → straightforward: copy that data into the
%                            canonical slot, unchanged.
%   >1 matching positions → this DF recorded MULTIPLE raw nodes that all
%                            collapse to the same canonical identity (e.g.
%                            3 units on the same channel, when REG='chans'
%                            — see "WHY MULTIPLE MATCHES CAN HAPPEN" below).
%                            Pool them via poolFn (default @mean).
%
% REG vs FTR — WHY THERE ARE TWO AXIS NAMES IN PLAY
% ----------------------------------------------------
% REG (regAxis, the argument you pass in) is whichever axis carries stable
% cross-session IDENTITY — e.g. 'unit' (post-unitMatch, truly comparable
% across sessions) or 'chans' (pre-unitMatch, channel position as a proxy
% for identity). FTR (ftrAxis, resolved internally below) is whichever
% axis actually OWNS the real array dimension in DF.df — the one you can
% index into and reshape. These are often literally the same axis
% (REG='unit', and 'unit' owns its own dimension) — but not always:
% 'chans' and 'unit' are co-indexed (same length, same positions, just two
% different label vectors over the one physical dimension — see
% CoRegistration_Design.md), and 'chans' typically does NOT own a
% dimension of its own (ptr.chans.dim == []). If you pass REG='chans',
% this function has to go find 'unit' (the sibling that DOES own the
% dimension) before it can actually slice/reshape any data — REG tells you
% *what identity to align on*, FTR tells you *where the data lives*.
%
% WHY MULTIPLE MATCHES CAN HAPPEN
% ----------------------------------
% Example: REG='chans' (channel position, pre-unitMatch). Session A has 3
% units all recorded on the same physical channel 7 (chans=[7 7 7],
% unit=[10 11 12]). When aligning to canonical channel 7, all 3 of those
% units collapse into ONE canonical slot — there's no way to keep them
% separate once you've chosen "channel" as the identity axis, so they get
% averaged (or whatever poolFn does) into that one slot. This is the
% "channel_avg" mode from CoRegistration_Design.md. If REG='unit' instead
% (post-unitMatch), each matched unit has its own stable identity, so this
% multi-match case becomes structurally impossible (always 0 or 1 match).
%
% WRITES (per DF, after alignment)
% -----------------------------------
%   DF.ax.(regAxis) = canonical REG values (the union, sorted) — every
%                     aligned DF now has the IDENTICAL value here.
%   DF.ax.(ftrAxis) = this DF's own values reslotted into canonical order
%                     (0/""-filled placeholder where absent — the label
%                     equivalent of the NaN-filled data).
%   DF.df           = NaN-filled / pooled along ftrDim to match canonical
%                     width — every aligned DF now has the SAME size along
%                     ftrDim (nCanon), even though they started different
%                     sizes.
%
% INFERENCE-TIME PROJECTION (canonRegOverride)
% ---------------------------------------------
% Pass canonRegOverride (the canonical set returned by an earlier batch call,
% e.g. cached on mdlObj.fitSentinel at fit time) to align a NEW single DF
% (TF = {DF_X}) onto that SAME fixed set of canonical positions, instead of
% deriving a fresh union from TF itself — which for a single new DF would be
% meaningless (a DF trivially "aligns" to its own values). This is the
% mechanism CoRegistration_Design.md's "Inference-Time Projection" section
% describes: canonical values missing from DF_X fall through to CASE 1 below
% (structural-absence fill, same as fit-time — resolved to 0 by the caller's
% terminal zero-fill before it reaches a model, never here); values in DF_X
% that aren't in canonRegOverride are simply never read by the canonical-value
% loop below, i.e. dropped, with no special-case code needed for either rule.
%
% [TF_aligned, canonReg, ftrAxis] — canonReg/ftrAxis are always returned
% (freshly computed, or echoed back when canonRegOverride was supplied) so a
% batch (fit-time) caller can cache them as a sentinel for later single-DF
% (transform-time) calls.

    fprintf('[nexOp_alignCoAxes] aligning co-registered axes: REG=%s across %d DFs\n', regAxis, numel(TF));
    if nargin < 3 || isempty(poolFn), poolFn = @mean; end
    if nargin < 4, canonRegOverride = []; end
    regAxis = char(regAxis);

    % ── Find first non-empty DF ───────────────────────────────────────────
    % We need ONE concrete DF to serve as a reference for figuring out
    % where the FTR dimension physically lives (see the next section) —
    % any DF that actually has the regAxis field will do, since the
    % dimension layout (which axis owns which dim) is a property of the
    % DF *shape*, not of which specific values that DF happens to contain.
    nonempty = find(~cellfun(@(x) isempty(x) || ~isfield(x,'ax') || ...
                             ~isfield(x.ax, regAxis), TF));
    if isempty(nonempty)
        fprintf('[nexOp_alignCoAxes] no DF has ax.%s — nothing to align.\n', regAxis);
        TF_aligned = TF; canonReg = canonRegOverride(:); ftrAxis = ''; return;
    end
    refDF = TF{nonempty(1)};

    % ── Canonical set = union(ax.REG) across all DFs, UNLESS a fixed set was
    % supplied (canonRegOverride — inference-time projection onto an already-
    % established fit-time canonical set; see the header comment above) ────
    % Continuing the running example: DF_A.ax.unit=[10 20 30],
    % DF_B.ax.unit=[20 30 40 50]. unique(vertcat(...)) of both gives
    % [10 20 30 40 50] — every identity that showed up ANYWHERE, sorted,
    % deduplicated. This union is what every DF gets reslotted into below.
    % Numeric REG (e.g. matched unit IDs) is unioned directly; non-numeric
    % REG (e.g. region name strings) is coerced to string first since you
    % can't take a numeric union of category labels.
    if ~isempty(canonRegOverride)
        canonReg = canonRegOverride(:);
    else
        allReg = cellfun(@(df) df.ax.(regAxis)(:), TF(nonempty), 'UniformOutput', false);
        if all(cellfun(@isnumeric, allReg))
            canonReg = unique(vertcat(allReg{:}));
        else
            % Can't comma-list-expand a function call's return value in place
            % (cellfun(...){:} is invalid) — needs an intermediate variable.
            allRegStr = cellfun(@(v) string(v(:)), allReg, 'UniformOutput', false);
            canonReg  = unique(vertcat(allRegStr{:}));
        end
    end
    nCanon = numel(canonReg);
    if nCanon == 0, TF_aligned = TF; ftrAxis = ''; return; end

    % ── Resolve FTR axis and its DF dimension ─────────────────────────────
    % refPtr may come back as a plain struct or as an axis-pointer object
    % depending on the constructor — isfield() always returns false for a
    % non-struct type even when the property genuinely exists (fieldnames()
    % and dynamic dot-access work fine on either). Check membership against
    % fieldnames(refPtr) instead so this resolves correctly regardless of
    % which form refPtr takes.
    refPtr = nexInit_axisPointer(refDF.df, refDF.ax);
    refPtrFields = fieldnames(refPtr);
    if ismember(regAxis, refPtrFields) && ~isempty(refPtr.(regAxis).dim)
        % Simple case: REG owns its own DF dimension directly (e.g.
        % REG='unit' and 'unit' really is a real array dimension). FTR is
        % just REG itself here — nothing to resolve.
        ftrAxis = regAxis;
        ftrDim  = refPtr.(regAxis).dim;
    else
        % REG is a co-indexed LABEL with no dimension of its own (e.g.
        % REG='chans', ptr.chans.dim==[]). Walk the co-index registry to
        % find the sibling axis that DOES own a real dimension — in the
        % running example that would be 'unit' (chans and unit are
        % co-indexed: same length, same positions, ptr.unit.dim is real).
        % That sibling becomes ftrAxis; its dimension becomes ftrDim. All
        % the actual df slicing/reshaping below happens along ftrDim —
        % regAxis is only ever used to decide *which* canonical slot a
        % given position belongs to.
        coIdx   = nexOp_coIndexPairs(refDF.ax);
        ftrAxis = '';
        ftrDim  = [];
        for p = 1:numel(coIdx)
            pair = coIdx{p};
            if ~ismember(regAxis, pair), continue; end
            for m = 1:numel(pair)
                cand = char(pair{m});
                if strcmp(cand, regAxis), continue; end
                if ismember(cand, refPtrFields) && ~isempty(refPtr.(cand).dim)
                    ftrAxis = cand;
                    ftrDim  = refPtr.(cand).dim;
                    break;
                end
            end
            if ~isempty(ftrAxis), break; end
        end
        if isempty(ftrAxis)
            % Neither regAxis nor any of its co-indexed siblings owns a
            % real dimension — there's nothing to align data along, so
            % bail out and hand back the input untouched rather than guess.
            warning('nexOp_alignCoAxes: no owning dimension found for REG=%s', regAxis);
            TF_aligned = TF; return;
        end
    end

    % ── Align each DF to the canonical REG set ────────────────────────────
    % For every DF, build a fresh df/ax pair sized to the canonical width
    % (nCanon along ftrDim) and copy/pool each DF's own data into the
    % correct canonical slot, position by position.
    TF_aligned = TF;
    nSkipped = 0;
    for i = 1:numel(TF)
        if isempty(TF{i}) || ~isfield(TF{i}.ax, regAxis)
            nSkipped = nSkipped + 1;
            continue;
        end
        DF      = TF{i};
        regVals = DF.ax.(regAxis);   % this DF's own REG identities (pre-alignment)
        ftrVals = DF.ax.(ftrAxis);   % this DF's own FTR values (pre-alignment)

        % Inference-time only: how much of THIS DF's own data falls outside
        % the fixed canonical set it's being projected onto (dropped, per
        % CASE 3 of the header comment above)? Not meaningful for a fresh
        % union — by construction nothing is ever dropped there.
        if ~isempty(canonRegOverride)
            if isnumeric(regVals)
                matched = ismember(double(regVals(:)), double(canonReg));
            else
                matched = ismember(string(regVals(:)), string(canonReg));
            end
            dropRatio = 1 - mean(matched);
            if dropRatio > 0.2
                warning('nexOp_alignCoAxes:highDropRatio', ...
                    ['[nexOp_alignCoAxes] %.0f%% of this DF''s %s values are ' ...
                     'outside the fit-time canonical set and will be dropped ' ...
                     '(row %d of %d).'], dropRatio*100, regAxis, i, numel(TF));
            end
        end
        sz      = size(DF.df);
        nDims   = max(ndims(DF.df), ftrDim);
        sz_out  = sz; sz_out(ftrDim) = nCanon;   % everything the same size except ftrDim, which becomes nCanon

        % Allocate the output array pre-filled with "structural absence"
        % markers. NaN for float data (distinguishable from a real zero);
        % 0 only as a fallback for integer/logical types that can't
        % represent NaN at all.
        if isfloat(DF.df)
            df_out = nan(sz_out, 'like', DF.df);
        else
            df_out = zeros(sz_out, 'like', DF.df);
        end
        % Same idea for the label array: 0 (numeric) or "" (string) marks
        % a canonical slot this DF never filled.
        if isnumeric(ftrVals)
            ftr_out = zeros(nCanon, 1, class(ftrVals));
        else
            ftr_out = repmat("", nCanon, 1);
        end

        % Walk the canonical list ONE VALUE AT A TIME (e.g. ci=1 -> cv=10,
        % ci=2 -> cv=20, ... for the running example's [10 20 30 40 50]),
        % and for each one ask "does THIS DF have anything matching cv?"
        for ci = 1:nCanon
            cv = canonReg(ci);
            if isnumeric(cv)
                localIdx = find(regVals == cv);
            else
                localIdx = find(strcmp(string(regVals), string(cv)));
            end

            % S_out addresses canonical slot ci along ftrDim, ':' elsewhere
            % — e.g. for a [time x unit] array with ftrDim=2, this is
            % equivalent to df_out(:, ci).
            S_out = repmat({':'}, 1, nDims); S_out{ftrDim} = ci;

            if isempty(localIdx)
                % CASE 1 — 0 matches: e.g. DF_A asking about cv=40. DF_A
                % never recorded unit 40, so localIdx is empty and we do
                % nothing — df_out(:,ci) simply stays NaN (or 0), exactly
                % the "structural absence" fill already allocated above.

            elseif numel(localIdx) == 1
                % CASE 2 — exactly 1 match: e.g. DF_A asking about cv=20.
                % DF_A.ax.unit has 20 at position 2 (localIdx=2) — copy
                % that one column of real data straight across into the
                % canonical slot, no pooling needed.
                S_in = repmat({':'}, 1, nDims); S_in{ftrDim} = localIdx;
                df_out(S_out{:}) = DF.df(S_in{:});
                ftr_out(ci)      = ftrVals(localIdx);

            else
                % CASE 3 — >1 matches: e.g. REG='chans' and THIS DF has 3
                % separate units all sitting on canonical channel cv.
                % localIdx lists all of their positions; slice out all of
                % them at once and collapse along ftrDim via poolFn
                % (default @mean) into the single canonical slot.
                S_in = repmat({':'}, 1, nDims); S_in{ftrDim} = localIdx;
                slice = DF.df(S_in{:});
                df_out(S_out{:}) = applyPoolFn(slice, ftrDim, poolFn);
                ftr_out(ci)      = ftrVals(localIdx(1));  % first as representative
            end
        end

        DF.df           = df_out;
        DF.ax.(ftrAxis) = ftr_out;    % this DF's FTR values, now in canonical order/width
        DF.ax.(regAxis) = canonReg;   % every aligned DF now shares this SAME array
        TF_aligned{i}   = DF;
    end
    skipMsg = '';
    if nSkipped > 0
        skipMsg = sprintf(', %d skipped (no ax.%s)', nSkipped, regAxis);
    end
    fprintf('[nexOp_alignCoAxes] aligned %d DFs to canonical %s width %d (ftrAxis=%s)%s\n', ...
            numel(TF) - nSkipped, regAxis, nCanon, ftrAxis, skipMsg);
end


% ── Pool multiple raw nodes into one canonical slot ───────────────────────
% Thin wrapper so poolFn can be any reduction function (@mean, @median, a
% custom handle) without every call site needing to know whether that
% function supports an 'omitnan' flag. Most do (mean, median, sum, ...);
% for ones that don't, the catch falls back to calling it without the flag.
function val = applyPoolFn(slice, dim, poolFn)
    try
        val = poolFn(slice, dim, 'omitnan');
    catch
        val = poolFn(slice, dim);
    end
end
