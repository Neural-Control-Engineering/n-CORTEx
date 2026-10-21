function T = buildLongSTAT(STAT, variables, gridCols, targetInfo)
% buildLongSTAT  Long-format reshape of an already-compiled STAT table --
% one row per (trial, <feature axis level>, <gridCols combo>) -- built on
% top of nexOp_stackSTAT.m (untouched -- this is a thin, separate
% post-processor, not a modification of that more heavily-depended-on
% function). Shared "compiled STAT -> long format" step for anything that
% needs a canonically-named table to fit/draw against: mdlObj_lme's
% nexFit_lme.m (per combo-child, for fitlme) and nexObj_violin (either
% standalone off its own compileSTAT, or reading an already-built one off
% mdlObj_lme's RESULTS.T_long) both call this -- see DESIGN.md section 4.
%
% Renamed from buildChainTable.m (which lived in
% Analysis/Statistics/MixedEffect/) once a second, non-chain caller
% existed -- nothing in this table's shape is chain-specific, so that name
% described its first caller, not its content. Also generalized: takes
% STAT and targetInfo explicitly instead of reading mdlObj.STAT/
% mdlObj.collector.Target internally, so it works for any caller holding a
% compiled STAT table, not just an mdlObj.
%
% Two differences from build_bandPowerRegionTable.m (which stays exactly
% as the standalone pipeline uses it today -- this is a new sibling, not a
% modification):
%   1. That file always renames whatever the target points to into the
%      fixed column name "condition" (and the subject category into
%      "subject"). This instead pulls each name in `variables` from the
%      compiled STAT/G table BY ITS REAL NAME, no renaming. The response
%      column is always literally named "df" (Nexus's own .df convention)
%      -- fitlme(T, formula) then needs no renaming step at all.
%   2. That file hardcodes STAT.ax(1).f / the column name "band" --
%      correct only for the band-power pipeline. This resolves the
%      flattened feature axis GENERICALLY instead, the same way
%      nexOp_stackSTAT.m itself already does (whichever ax field has
%      ptr.(name).dim==2, not a literal "f") -- so a different domain
%      (SSM timescales, firing rates, ...) flows through under its own
%      real axis name.
%
%   STAT       : an already-compiled STAT table (e.g. mdlObj.STAT after
%                compileSTAT()/fitByCombo() has sliced it to one combo, or
%                a plain nexObj's own nexOp_compileSTAT() output). Never
%                compiled here -- the caller owns that step.
%   variables  : string array of real column names to pull. Each is
%                looked up verbatim in G first, then with an "h5_" prefix
%                (nexOp_compileSTAT's HDF5-backed-category naming
%                convention) as a fallback.
%   gridCols   : cell array of ADDITIONAL grid dimension column names to
%                pull from G, beyond the feature axis (e.g. {'chans','t'}).
%                Any name not actually present in G is silently skipped.
%   targetInfo : struct('name', <real column name>, 'nBins', <nBins>) when
%                one of `variables` should be quantized (same
%                nexOp_quantizeY mechanism build_bandPowerRegionTable.m
%                uses, scoped to just this one column), or [] to skip
%                quantization entirely (e.g. a standalone nexObj_violin
%                call with no Target concept at all).
%
%   T : table, one row per (trial, <feature axis>, <gridCols>): trial,
%       <feature axis name>, df, <variables...>, <gridCols...>.
%
% WORKED EXAMPLE: one combo-child (one cci x side stratum) with
%   variables  = ["sessionLabel_subj", "h5_responseThreshold_g"]
%   gridCols   = {'chans', 't'}
%   targetInfo = struct('name', "h5_responseThreshold_g", 'nBins', 2)
% and, say, 24 trials x 16 chans x 5 t-windows x 2 bands in that stratum.

    if nargin < 4, targetInfo = []; end

    % STAT = this combo-child's own slice (24*16*5 = 1920 rows, each
    % STAT.df{i} shaped [16 chans x 2 bands x 5 t])
    [Z, G, ~] = nexOp_stackSTAT(STAT);
    % Z: [1920 x 2]   -- one column per band, nexOp_stackSTAT's own flatten
    % G: 1920-row table -- trialNumber, trialUID, chans, t,
    %    sessionLabel_subj, h5_responseThreshold_g, ... (every STAT column
    %    that ISN'T df/ax/ptr, expanded out row-for-row to match Z's rows)
    %
    % T.trial is built from trialUID, NOT trialNumber -- trialNumber is
    % the literal DTS per-session count, which resets to 1 at the start of
    % EVERY recording session, so it only disambiguates trials WITHIN one
    % session. A single subject with several sessions inside the same
    % combo-child's STAT (ordinary -- one CTG stratum routinely spans
    % multiple sessions) then has multiple real, DIFFERENT trials all
    % sharing trialNumber==1 -- confirmed directly on real data: 4 separate
    % STAT rows for one subject/stratum all had trialNumber==1, which this
    % function's own per-trial quantization (below) was silently averaging
    % together as if they were one trial. trialUID (nexOp_compileSTAT's
    % own STAT row index at compile time) has no such reset, so it's safe
    % to treat as "one real trial" anywhere in this file. trialNumber
    % itself is left on STAT/G untouched (still potentially useful as a
    % within-session display value) -- only WHICH column this function
    % itself treats as the true trial key changes.

    [fAxisName, fLabels] = resolveFeatureAxis(STAT);
    % fAxisName = "f" (the pMap.f-pooled axis, in this band-power example)
    % fLabels   = ["beta"; "gamma"]   (nFeat = 2, matches Z's 2 columns)
    if numel(fLabels) ~= size(Z, 2)
        error('buildLongSTAT:featureMismatch', ...
            'STAT.ax(1).%s has %d labels but Z has %d columns.', fAxisName, numel(fLabels), size(Z, 2));
    end

    nRows = height(G);    % 1920
    nFeat = numel(fLabels); % 2

    if ~ismember('trialUID', G.Properties.VariableNames)
        error('buildLongSTAT:noSampleNumber', ...
            'G has no trialUID column -- expected a real STAT column (nexOp_compileSTAT sets it directly).');
    end

    T = table();
    T.trial           = repmat(G.trialUID, nFeat, 1);   % 3840x1 (1920*2)
    T.(char(fAxisName)) = categorical(repelem(fLabels(:), nRows, 1));
    % T.f = ["beta";"beta";...(1920 times)...;"gamma";"gamma";...] -- first
    % 1920 rows are "beta" (G repeated once per band, band-major blocks),
    % matching Z(:)'s own column-major flatten order below.
    T.df              = Z(:);   % column-major flatten -- matches the repmat/repelem block order
    % T.df(1:1920)    = Z(:,1)  (every row's beta-band value)
    % T.df(1921:3840) = Z(:,2)  (every row's gamma-band value)

    for vi = 1:numel(variables)
        name   = char(variables(vi));
        % vi=1: name="sessionLabel_subj" -- vi=2: name="h5_responseThreshold_g"
        srcCol = resolveColumn(G, name);
        rawVal = G.(srcCol);

        isTextType = isstring(rawVal) || ischar(rawVal) || iscellstr(rawVal);
        parsedNumeric = [];
        if isTextType
            % An HDF5-backed column's MATLAB storage type (string/char)
            % reflects dtsIO's read path for that dfID, NOT whether the
            % real variable is a label or a continuous value -- the same
            % ambiguity build_bandPowerRegionTable.m resolves for its one
            % hardcoded conditionVar via str2double before deciding
            % categorical vs continuous (confirmed directly: live
            % rawVal for h5_responseThreshold_g IS string, same as
            % sessionLabel_subj's rawVal, even though one is a true label
            % and the other is a continuous value stored as text).
            % Trusting the MATLAB type alone -- the bug fixed here --
            % wrapped a continuous variable in categorical() with one
            % level per distinct value, which fitlme then dummy-codes
            % into as many fixed-effect columns as distinct values,
            % causing "Fixed Effects design matrix X must be of full
            % column rank" once that count approaches a cell's row/group
            % count. str2double-and-check-for-NaN is the same test
            % build_bandPowerRegionTable.m already relies on.
            parsedNumeric = str2double(string(rawVal));
            if ~any(isnan(parsedNumeric))
                fprintf(['[buildLongSTAT] variable "%s" is %s but parses fully as numeric -- ' ...
                         'treating as continuous via str2double (same convention ' ...
                         'build_bandPowerRegionTable.m uses for its conditionVar), not categorical.\n'], ...
                    name, class(rawVal));
                isTextType = false;
            end
        end

        if isTextType
            % e.g. name="sessionLabel_subj", rawVal = ["rat07";"rat07";"rat12";...] (1920x1)
            T.(name) = categorical(repmat(string(rawVal), nFeat, 1));
            % T.sessionLabel_subj = 3840x1 categorical, same "rat07" block
            % repeated once per band, exactly like T.trial above.
        else
            if ~isempty(parsedNumeric)
                vals = parsedNumeric;   % text that fully parsed as numeric above
            else
                vals = double(rawVal);
            end
            % e.g. name="h5_responseThreshold_g", vals = [1.2;1.2;0.4;...] (1920x1, continuous)
            % Quantize only when targetInfo names THIS variable -- same
            % nexOp_quantizeY mechanism build_bandPowerRegionTable.m
            % always applies to its one hardcoded condition variable, now
            % scoped to whichever real column the caller designated (or
            % skipped entirely when targetInfo is [], e.g. a standalone
            % nexObj_violin call with no Target concept at all).
            isTarget = ~isempty(targetInfo) && isfield(targetInfo, 'name') && ...
                (strcmp(char(targetInfo.name), name) || strcmp(['h5_' char(targetInfo.name)], name));
            if isTarget
                nBins = Inf;
                if isfield(targetInfo, 'nBins'), nBins = targetInfo.nBins; end
                rawVals = vals;
                % Quantize from DEDUPED per-trial values, not vals as-is --
                % vals is still at G's row granularity (one row per trial x
                % feature-axis level, nexOp_stackSTAT's own flatten), so a
                % trial with more surviving band/chans/t rows than another
                % would be over-weighted in quantile(), skewing the cutoff
                % away from the true per-trial median (confirmed directly:
                % an even ~50/50 per-ROW split produced a 27/47 per-TRIAL
                % split on real data before this fix). Compute edges off
                % one value per trial, then broadcast each trial's bin
                % assignment back out to its expanded rows -- every row
                % sharing a trialUID shares the same raw value, so this
                % is a lossless re-expansion, not an approximation.
                %
                % Keyed on trialUID, NOT trialNumber -- trialNumber
                % resets to 1 every new recording session, so grouping by
                % trialNumber alone silently merged different subjects'/
                % sessions' own "trial 1" together as if they were the same
                % trial (confirmed directly on real data: one subject had
                % 4 separate sessions all sharing trialNumber==1 within one
                % stratum). trialUID never resets, so it's a genuine
                % one-row-per-real-trial key regardless of how many
                % sessions/subjects this combo-child's STAT spans.
                [trialIDs, firstRowPerTrial] = unique(G.trialUID, 'stable');
                valsTrial  = vals(firstRowPerTrial);
                qTrial     = nexOp_quantizeY(valsTrial, nBins);
                [~, rowToTrialIdx] = ismember(G.trialUID, trialIDs);
                vals = qTrial(rowToTrialIdx);
                % e.g. nBins=2 -> vals = [1;1;0;...] (1920x1, now binary)
                if isequal(vals, rawVals)
                    fprintf(['[buildLongSTAT] WARNING: quantizeY was a pass-through ' ...
                             '(nBins=%s) for Target variable "%s" -- still continuous.\n'], ...
                        mat2str(nBins), name);
                else
                    % Quantized bins are discrete LEVELS, meant to be
                    % fit as a categorical factor (matching
                    % build_bandHierarchy.m's own Tc.condition =
                    % categorical(Tc.condition) cast) -- not left as a
                    % plain numeric column, which fitlme would otherwise
                    % treat as a continuous slope instead of a factor.
                    T.(name) = categorical(repmat(string(vals), nFeat, 1));
                    % T.h5_responseThreshold_g = 3840x1 categorical, levels "0"/"1"

                    % Verify balance for THIS stratum directly -- vals is
                    % still at G's row granularity (one row per trial x
                    % feature-axis level, nexOp_stackSTAT's own flatten),
                    % so also dedupe by trialUID to show the real
                    % per-TRIAL bin counts, not inflated/skewed by
                    % however many band/chans/t rows each trial expanded
                    % into.
                    uLevels = unique(vals);
                    counts  = arrayfun(@(u) sum(vals == u), uLevels);
                    fprintf('[buildLongSTAT] "%s" quantized (nBins=%s) -- per-row counts: %s\n', ...
                        name, mat2str(nBins), strjoin(compose("level %d: n=%d", uLevels, counts), ', '));
                    % qTrial is the actual per-trial quantized assignment
                    % the fix above now computes edges from directly --
                    % printing it here (rather than re-deriving it from
                    % the broadcast-back-out vals) confirms the balance of
                    % the SAME values that drove the quantile edges.
                    uLevelsT = unique(qTrial);
                    countsT  = arrayfun(@(u) sum(qTrial == u), uLevelsT);
                    fprintf('[buildLongSTAT] "%s" quantized (nBins=%s) -- per-TRIAL counts (%d trials): %s\n', ...
                        name, mat2str(nBins), numel(qTrial), ...
                        strjoin(compose("level %d: n=%d", uLevelsT, countsT), ', '));
                    continue
                end
            end
            T.(name) = repmat(vals, nFeat, 1);
            % (only reached when isTarget is false, or quantizeY was a
            % pass-through -- a genuinely continuous predictor stays a
            % plain double column, fit by fitlme as a continuous slope.)
        end
    end

    % Exclude fAxisName ("f" in the band-power example) from gridCols --
    % it is ALREADY built above via resolveFeatureAxis + repelem/Z(:), and
    % G can ALSO happen to carry its own, UNRELATED column of the same
    % name (confirmed directly: G.f exists but holds a different, stale
    % per-row tag, not the true per-cell band label). Without this
    % exclusion, gridCols containing "f" (e.g. inherited from an original
    % LDA domain.SWP that legitimately swept band/chans/t as three grid
    % axes) silently OVERWRITES the correct T.f with G's unrelated
    % same-named column -- a coincidental name collision, not a
    % real second source of truth for the feature axis (confirmed
    % directly: T.f was correct immediately after construction and only
    % corrupted once this loop reprocessed "f" a second time).
    gridCols = gridCols(ismember(gridCols, G.Properties.VariableNames) & ~strcmpi(gridCols, char(fAxisName)));
    for gi = 1:numel(gridCols)
        gc = gridCols{gi};
        % gi=1: gc="chans" -- gi=2: gc="t"
        T.(gc) = categorical(repmat(string(G.(gc)), nFeat, 1));
        % T.chans = 3840x1 categorical ["C3";"C4";...], T.t likewise
    end
    % Final T: 3840 rows x 6 columns --
    % trial | f | df | sessionLabel_subj | h5_responseThreshold_g | chans | t
    % (column order as assigned above; "f" sits before "df" here only
    % because it was assigned first -- downstream consumers never rely on
    % column ORDER, only on column NAMES.)
end

function [fAxisName, fLabels] = resolveFeatureAxis(STAT)
% The flattened feature axis -- whichever ax field has ptr.(name).dim==2
% -- same role-based detection nexOp_stackSTAT.m uses internally (never a
% hardcoded name like "f"), so this generalizes across domains instead of
% assuming band-power's own axis name.
%
% Example: ax_ref = struct('f', ["beta","gamma"], 'chans', [...], 't', [...]),
% ptr_ref.f.dim = 2, ptr_ref.chans.dim/ptr_ref.t.dim = something else ->
% isF = [true, false, false] -> fAxisName = "f", fLabels = ["beta";"gamma"].
% For a non-band-power domain this might instead resolve e.g. fAxisName =
% "timescale" with fLabels = ["tau1";"tau2";"tau3"] -- same mechanism,
% different real axis.
%
% ptr_ref is a nexObj_ptr (handle & dynamicprops) -- isfield() on it
% returns FALSE for every field regardless of whether it genuinely exists
% (verified directly: dynamicprops does NOT make isfield() work here,
% despite that being the usual exception people expect -- tested, not
% assumed). Same pitfall family as DF_postOp/collector.Domain elsewhere in
% this codebase; fieldnames-membership is the correct workaround, same as
% used there.
    if iscell(STAT.ax), ax_ref = STAT.ax{1}; else, ax_ref = STAT.ax(1); end
    axFields = fieldnames(ax_ref);
    ptr_ref  = STAT.ptr(1);
    ptrFields = fieldnames(ptr_ref);
    isF      = cellfun(@(f) ismember(f, ptrFields) && isequal(ptr_ref.(f).dim, 2), axFields);
    if ~any(isF)
        error('buildLongSTAT:noFeatureAxis', ...
            'No ax field has ptr.(name).dim==2 -- STAT.ptr wasn''t built via nexInit_axisPointer, or this STAT has no feature axis.');
    end
    fAxisName = string(axFields{find(isF, 1)});
    fLabels   = string(ax_ref.(char(fAxisName)));
end

function srcCol = resolveColumn(G, name)
% Verbatim name first, then the "h5_"-prefixed HDF5-backed-category
% variant (nexOp_compileSTAT's own naming convention) as a fallback.
    if ismember(name, G.Properties.VariableNames)
        srcCol = name;
        return;
    end
    h5Name = ['h5_' name];
    if ismember(h5Name, G.Properties.VariableNames)
        srcCol = h5Name;
        return;
    end
    error('buildLongSTAT:noSuchColumn', ...
        'variable "%s" (or "%s") not found among STAT''s own columns in G.', name, h5Name);
end
