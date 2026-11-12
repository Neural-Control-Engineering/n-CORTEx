function nexOp_quantizePerCombo(obj, dfID_source, dfID_target, numBins, binLabels)
% Quantile-quantize dfID_source into numBins groups, computed SEPARATELY
% within each combo of obj's currently-selected CTG columns (whatever that
% is right now -- subj alone, subj x phase, anything else) -- then writes
% the resulting label back to disk as a brand-new per-trial category named
% dfID_target, so it becomes a real, persistent, selectable category from
% then on (readable the same way as any other, e.g. via
% dtsIO_readTF_category(nexon, "h5--"+dfID_target, ...)), not just an
% in-memory STAT column that vanishes with this session.
%
% This is the actual mechanism behind LME's/LDA's own "per-subject"
% thresholds -- neither pipeline runs a bespoke per-subject algorithm.
% buildLongSTAT.m (once per fitByCombo combo-child) and cvPermute's own
% per-combo fold loop both call nexOp_quantizeY -- just AFTER the data has
% already been sliced down to one combo (typically one subject) by
% fitByCombo/the combo loop, so by the time quantizeY runs it only ever
% sees that one group's own values, and its quantile edges land wherever
% THAT group's histogram actually splits evenly. fitSWPGrid has no such
% "slice first" step to lean on -- its own CTG combos are formed directly
% off whatever discrete STAT columns already exist
% (mdlObject.fitSWPGrid: comboTbl = unique(STAT(:,validCTG),'rows')) -- so
% a quantized label meant to BE one of those CTG columns has to already
% exist, pre-split per combo, as a real STAT/DTS column, before
% fitSWPGrid ever runs. This function is that one step.
%
%   obj         : mdlObject or nexObject subclass instance. Needs
%                 obj.Origin (the categorical ctg parent -- same
%                 assumption any fresh, non-precompiled compileSTAT call
%                 already makes) and obj.collector.View.CTG (the
%                 currently-selected CTG columns -- same bus both object
%                 families carry; read directly, NOT via domain.CTG, so
%                 this works off whatever's live in the figure's own CTG
%                 selection without any extra wiring).
%   dfID_source : real dfID to quantize, e.g. "responseThreshold_g"
%   dfID_target : new dfID name the quantized label will be written under
%                 and read back as later, e.g. "thresholdQuantile"
%   numBins     : passed straight through to nexOp_quantizeY, per combo
%   binLabels   : (optional) string array of length numBins, one label per
%                 quantile RANK (bin 1 = lowest in every combo, etc. --
%                 the same literal label can mean a different numeric
%                 range in a different combo, which is the point -- a
%                 "low" trial for one subject and a "low" trial for
%                 another aren't the same raw value, just the same rank).
%                 Omit to fall back to each combo's own literal
%                 "startVal--stopVal" range instead, from mat2str'd
%                 nexOp_quantizeY edges -- no identity ("low"/"high",
%                 "bottom"/"top", ...) is assumed or hardcoded.
%
% Writes directly to disk via dtsIO_writeDF (per real DTS row, numeric
% dtsIdx -> dtsIO_writeHDF5's "update existing row" branch -- no new
% manifest rows, no bulk splice). No MATLAB return value.
    if nargin < 5, binLabels = string.empty; end
    if ~isempty(binLabels) && numel(binLabels) ~= numBins
        error('nexOp_quantizePerCombo:binLabelsSize', ...
            'binLabels has %d entries but numBins=%d -- need exactly one label per bin.', ...
            numel(binLabels), numBins);
    end

    nexon = obj.nexon;

    % Fresh compile against dfID_source directly (not obj's own default
    % dfID_source) -- S_categories/S_items/idxSel/precompiled all [] so
    % nexOp_compileSTAT resolves everything fresh from obj.Origin's own
    % selectionBus, same as any other first-time (non-precompiled) caller.
    [STAT, ~, ~] = nexOp_compileSTAT(obj, dfID_source, [], [], [], [], []);
    if isempty(STAT) || ~ismember('dtsRowIdx', STAT.Properties.VariableNames)
        error('nexOp_quantizePerCombo:noDtsRowIdx', ...
            'Compiled STAT has no dtsRowIdx column -- nexOp_compileSTAT did not attach it.');
    end

    % No nexOp_stackSTAT here -- STAT compiled against a flat scalar
    % dfID_source is already one row per trial, with STAT.df{i} holding
    % the scalar value directly, so there is no feature axis to flatten.
    % nexOp_stackSTAT's own expandAxCol tries to "expand" EVERY STAT.ax
    % field to match df's shape, including empty placeholder fields
    % (confirmed directly: an empty axVals makes n=0, so its
    % ceil(nTotal/n)=Inf, and repmat(...,Inf,1) errors) -- unnecessary
    % machinery for a source with no real feature axis to begin with.
    G = STAT;
    vals = cellfun(@(c) double(c), STAT.df);
    if ~isvector(vals) || numel(vals) ~= height(STAT)
        error('nexOp_quantizePerCombo:notScalar', ...
            'dfID_source "%s" did not flatten to one scalar value per trial -- check it is a flat (axis-less) dfID.', ...
            dfID_source);
    end
    vals = vals(:);

    % obj.collector.View.CTG -- the figure's own live CTG selection bus,
    % shared shape across mdlObject and nexObject (both carry
    % collector.View with selKeys.CTG/selections.CTG) -- not domain.CTG,
    % which is itself only ever a snapshot mirroring this same bus.
    ctgSel  = nex_returnSelectionMask(obj.collector.View);
    ctgCols = string(ctgSel.CTG);
    ctgCols = ctgCols(ctgCols ~= "" & ctgCols ~= "None");
    validCTG = ctgCols(ismember(ctgCols, string(G.Properties.VariableNames)));

    % dfID_source itself (bare or "h5_"-prefixed) is excluded even if it's
    % currently selected as a CTG column in the figure's own bus -- a live
    % CTG selection commonly used for OTHER purposes (e.g. fitSWPGrid
    % stratification) can legitimately include the very variable being
    % quantized here. Grouping by the continuous target itself degenerates
    % every combo to ~1 trial (confirmed directly: selecting it produced
    % 604 "combos" for 604 trials) and defeats the whole per-combo
    % mechanism -- it can never be a meaningful grouping key for its own
    % quantization.
    srcNames = unique([string(dfID_source), "h5_" + string(dfID_source)]);
    excluded = validCTG(ismember(validCTG, srcNames));
    validCTG = validCTG(~ismember(validCTG, srcNames));
    if ~isempty(excluded)
        fprintf('[nexOp_quantizePerCombo] excluding dfID_source itself from CTG grouping: [%s]\n', ...
            strjoin(excluded, ', '));
    end
    fprintf('[nexOp_quantizePerCombo] CTG = [%s] (%d valid grouping column(s) on compiled STAT)\n', ...
        strjoin(ctgCols, ', '), numel(validCTG));

    if isempty(validCTG)
        comboTbl = table();   % one implicit combo: everything
        nCombos  = 1;
    else
        comboTbl = unique(G(:, cellstr(validCTG)), 'rows');
        nCombos  = height(comboTbl);
    end
    fprintf('[nexOp_quantizePerCombo] %d combo(s)\n', nCombos);

    labelStr  = strings(height(G), 1);
    hasLabel  = false(height(G), 1);
    nWritten  = 0;
    nSkippedNaN = 0;

    for ci = 1:nCombos
        if isempty(validCTG)
            comboMask = true(height(G), 1);
            comboDesc = "(all rows)";
        else
            comboMask = true(height(G), 1);
            comboParts = strings(numel(validCTG), 1);
            for vi = 1:numel(validCTG)
                col = char(validCTG(vi));
                val = comboTbl.(col)(ci);
                comboMask  = comboMask & (G.(col) == val);
                % Per-column, not a single comboTbl{ci, cellstr(validCTG)}
                % multi-column curly extraction -- validCTG can mix string
                % (sessionLabel_subj/phase) and numeric (another CTG
                % column) column types, and table curly-indexing across
                % incompatible-type columns silently returns a
                % comma-separated list instead of one concatenated array
                % (confirmed directly: fed compose() 3 extra unpaired
                % arguments, "Format must have enough conversion operators
                % for the data arguments"). Looping column-by-column, same
                % as the comboMask loop right above, sidesteps this
                % entirely -- one scalar at a time, never concatenated.
                comboParts(vi) = sprintf("%s=%s", col, string(val));
            end
            comboDesc = strjoin(comboParts, ', ');
        end

        fprintf('[nexOp_quantizePerCombo] -- combo %d/%d: %s (n=%d) --\n', ...
            ci, nCombos, comboDesc, nnz(comboMask));

        valsCombo = vals(comboMask);
        [binIdx, edges] = nexOp_quantizeY(valsCombo, numBins);
        if isequal(binIdx, valsCombo)
            fprintf('[nexOp_quantizePerCombo]   WARNING: quantizeY was a pass-through (nBins=%d), still continuous. Skipped -- no label written for this combo.\n', ...
                numBins);
            continue;
        end

        % Human-readable per-bin range + occupancy, same convention as
        % nexAudit_quantizeEdges.m's own quantile-range text -- this is the
        % whole point of printing per-combo: each combo gets its OWN edges
        % (that's the "meaningful per-subject boundary" mechanism), so
        % seeing them side-by-side combo-by-combo is how you'd actually
        % notice one subject's split landing somewhere very different from
        % another's.
        binLabelText = strings(numBins, 1);
        for b = 1:numBins
            rangeTxt = sprintf('[%.4g, %.4g%s', edges(b), edges(b+1), ')');
            if b == numBins, rangeTxt = extractBefore(rangeTxt, ')') + "]"; end
            n_b = nnz(binIdx == b);
            labelTxt = "";
            if ~isempty(binLabels), labelTxt = sprintf(' -> label "%s"', binLabels(b)); end
            binLabelText(b) = sprintf('  bin %d: %s %s n=%d%s', b, dfID_source, rangeTxt, n_b, labelTxt);
        end
        fprintf('%s\n', strjoin(binLabelText, newline));

        comboIdxList = find(comboMask);
        for k = 1:numel(comboIdxList)
            bi = binIdx(k);
            gi = comboIdxList(k);
            if isnan(bi)
                nSkippedNaN = nSkippedNaN + 1;
                continue;
            end
            if ~isempty(binLabels)
                labelStr(gi) = binLabels(bi);
            else
                labelStr(gi) = sprintf("%.4g--%.4g", edges(bi), edges(bi + 1));
            end
            hasLabel(gi) = true;
        end
    end

    for gi = 1:height(G)
        if ~hasLabel(gi), continue; end
        DF = struct('df', labelStr(gi));
        dtsIO_writeDF(nexon, DF, dfID_target, G.dtsRowIdx(gi));
        nWritten = nWritten + 1;
    end

    fprintf('[nexOp_quantizePerCombo] wrote "%s" for %d/%d trial(s) (%d skipped: NaN target value)\n', ...
        dfID_target, nWritten, height(G), nSkippedNaN);
end
