function report = nexMigrate_vonfreyPreBuff(nexon, opts)
% Retroactively rebase legacy online von Frey event indices from a 0.5 s
% prebuffer to the 3.5 s convention, by adding (preBuffNew-preBuffOld)*fs
% samples to the affected HDF5-stored event values.
%
%   report = nexMigrate_vonfreyPreBuff(nexon)              % DRY RUN (no writes)
%   report = nexMigrate_vonfreyPreBuff(nexon, opts)
%
% BACKGROUND
%   Online von Frey packets briefly stored their event SAMPLE INDICES against a
%   0.5 s prebuffer, while the neural DFs (and, going forward, the host) use
%   3.5 s. Both index from the buffer start, so every event index of a 0.5-space
%   trial is a constant +((3.5-0.5)*fs)=+3000 samples short. This adds that
%   offset so all trials share one convention.
%
%   These indices are stored in HDF5 (one dfID per event, per trial) — NOT the
%   manifest — so this reads/writes through dtsIO_readDF / dtsIO_writeDF, which
%   handle row routing, patch files, and dataset overwrite. Which columns: the
%   signal_types 'event' types. Durations/scores are not indices and are skipped.
%
% SAFETY
%   - DRY RUN by default (opts.dryRun=true): reports intended changes, writes
%     nothing. Inspect report.changes, THEN re-run with opts.dryRun=false.
%   - On apply: writes a reversible change-log .mat (every row/dfID old->new)
%     into the DTS directory. Undo = subtract advanceSamp for those entries.
%     (Optional full-h5 copy via opts.backupH5=true — off by default; the h5 can
%     be large and the change is exactly invertible + guarded.)
%   - IDEMPOTENT: shift applied per-ROW only when still 0.5-space (onset marker
%     < threshold). Rows already at 3.5 s are skipped; re-running can't double-add.
%   - VERIFY: after writing, re-reads each cell and asserts it moved by exactly
%     advanceSamp.
%
% opts (all optional):
%   .dryRun      (true)        report only; no writes
%   .preBuffOld  (0.5)         legacy prebuffer (s) the indices were stored against
%   .preBuffNew  (3.5)         target prebuffer (s)
%   .fs          (1000)        slrt sample rate (Hz) for the s->samples conversion
%   .columns     ([] = auto)   explicit event-dfID list, overriding signal_types
%   .onsetCol    ("stimOnset") per-row 0.5-vs-3.5 discriminator; falls back to the
%                              row's min event index if absent/NaN
%   .rowMask     ([] = all)    logical/index restriction ANDed with the 0.5 guard
%   .backupH5    (false)       also copy each touched h5 file before writing
%
% report (struct): .columns, .advanceSamp, .threshSamp, .rowsShifted,
%   .rowsSkipped, .changes (table: row, sessionLabel, trialNumber, dfID, old, new),
%   .changeLogPath (apply only), .verifyOK (apply only).

    if nargin < 2, opts = struct(); end
    dryRun     = getOpt(opts, 'dryRun', false);
    preBuffOld = getOpt(opts, 'preBuffOld', 0.5);
    preBuffNew = getOpt(opts, 'preBuffNew', 3.5);
    fs         = getOpt(opts, 'fs', 1000);
    onsetCol   = string(getOpt(opts, 'onsetCol', "stimOnset"));
    colsOverride = getOpt(opts, 'columns', []);
    rowMaskIn    = getOpt(opts, 'rowMask', []);
    backupH5     = getOpt(opts, 'backupH5', false);

    advanceSamp = round((preBuffNew - preBuffOld) * fs);            % +3000 by default
    threshSamp  = round(((preBuffOld + preBuffNew) / 2) * fs);      % 2000 midpoint

    DTS   = nexon.console.BASE.DTS;
    nRows = height(DTS);
    allDFIDs = string(dtsIO_readDFIDs(DTS));   % manifest cols + HDF5 leaf dfIDs

    % ── Resolve the event-index dfIDs (must exist as readable dfIDs) ─────────
    if isempty(colsOverride)
        eventCols = string(nex_getEventTypes(nexon));    % signal_types 'event' IDs
    else
        eventCols = string(colsOverride);
    end
    eventCols = eventCols(ismember(eventCols, allDFIDs));
    if isempty(eventCols)
        error("nexMigrate_vonfreyPreBuff:noCols", ...
              "no event-index dfIDs found (checked signal_types 'event' types against dtsIO_readDFIDs)");
    end

    baseMask = true(nRows, 1);
    if ~isempty(rowMaskIn)
        if islogical(rowMaskIn), baseMask = rowMaskIn(:);
        else, baseMask = false(nRows,1); baseMask(rowMaskIn) = true; end
    end

    % In-memory (hybrid) rows have h5_path == "" — no HDF5 file to write into.
    % They must be skipped for the on-disk migration; if one nonetheless looks
    % 0.5-space it's flagged separately (report.inMemNeedsFix) so it isn't lost.
    if ismember('h5_path', DTS.Properties.VariableNames)
        onDisk = strlength(string(DTS.h5_path)) > 0;
    else
        onDisk = false(nRows,1);   % pure in-memory DTS — nothing to migrate on disk
    end

    % ── Per-row: read onset marker from HDF5, decide 0.5-space vs 3.5-space ──
    % All of a trial's event indices share the same offset, so the decision is
    % per-row (via the onset marker, nearest the prebuffer boundary), not per-cell.
    shiftRow      = false(nRows, 1);
    inMemNeedsFix = [];
    for r = 1:nRows
        if ~baseMask(r), continue; end
        onsetVal = rowOnsetValue(nexon, r, onsetCol, eventCols, allDFIDs);
        if isnan(onsetVal), continue; end
        is05 = onsetVal < threshSamp;
        if ~onDisk(r)
            if is05, inMemNeedsFix(end+1) = r; end %#ok<AGROW>
            continue;                 % never write in-memory rows to HDF5
        end
        shiftRow(r) = is05;
    end
    if ~isempty(inMemNeedsFix)
        fprintf("[vonfreyPreBuff] WARNING: %d in-memory row(s) look 0.5-space and were NOT touched (not on disk yet): %s\n", ...
                numel(inMemNeedsFix), mat2str(inMemNeedsFix));
    end

    % ── Build the change list (old -> new) for flagged rows ─────────────────
    changeRows = {};
    for r = find(shiftRow)'
        for c = 1:numel(eventCols)
            dfID = eventCols(c);
            old  = readIdx(nexon, dfID, r);
            if isempty(old) || any(isnan(old)), continue; end
            sl = safeStr(DTS, r, "sessionLabel");
            tn = safeNum(DTS, r, "trialNumber");
            changeRows(end+1,:) = {r, sl, tn, dfID, old, old + advanceSamp}; %#ok<AGROW>
        end
    end
    % Build explicitly (NOT cell2table, which collapses scalar old/new cells to
    % double columns). Keep old/new as CELLS so verify's {i} access and the
    % vector-event case both work uniformly.
    cvars = {'row','sessionLabel','trialNumber','dfID','old','new'};
    if isempty(changeRows)
        changes = table('Size',[0 6], ...
            'VariableTypes',{'double','string','double','string','cell','cell'}, ...
            'VariableNames',cvars);
    else
        changes = table( cell2mat(changeRows(:,1)), string(changeRows(:,2)), ...
            cell2mat(changeRows(:,3)), string(changeRows(:,4)), ...
            changeRows(:,5), changeRows(:,6), 'VariableNames', cvars);
    end

    report = struct();
    report.columns     = eventCols;
    report.advanceSamp = advanceSamp;
    report.threshSamp  = threshSamp;
    report.rowsShifted   = find(shiftRow)';
    report.rowsSkipped   = find(~shiftRow & baseMask & onDisk)';
    report.inMemNeedsFix = inMemNeedsFix;
    report.changes       = changes;

    fprintf("[vonfreyPreBuff] event dfIDs: %s\n", strjoin(cellstr(eventCols), ", "));
    fprintf("[vonfreyPreBuff] +%d samples to %d row(s); %d row(s) already 3.5-space (skipped).\n", ...
            advanceSamp, numel(report.rowsShifted), numel(report.rowsSkipped));

    if dryRun
        fprintf("[vonfreyPreBuff] DRY RUN — no changes written. Inspect report.changes, then re-run with opts.dryRun=false.\n");
        return;
    end
    if isempty(changeRows)
        fprintf("[vonfreyPreBuff] nothing to shift — no write performed.\n");
        report.changeLogPath = ""; report.verifyOK = true; return;
    end

    % ── Reversible change-log (cheap, exact undo) + optional h5 copy ─────────
    ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
    dtsDir = fileparts(char(DTS.h5_path(find(strlength(string(DTS.h5_path))>0,1))));
    report.changeLogPath = fullfile(dtsDir, sprintf("nexDTS_vonfreyPreBuff_changelog_%s.mat", ts));
    changelog = struct('changes', changes, 'advanceSamp', advanceSamp, ...
                       'preBuffOld', preBuffOld, 'preBuffNew', preBuffNew, 'fs', fs); %#ok<NASGU>
    save(report.changeLogPath, '-struct', 'changelog');
    fprintf("[vonfreyPreBuff] wrote reversible change-log -> %s\n", report.changeLogPath);
    if backupH5
        for hp = unique(string(DTS.h5_path(shiftRow)))'
            if strlength(hp)==0, continue; end
            copyfile(char(hp), char(strrep(hp, ".h5", sprintf(".backup_%s.h5", ts))));
        end
        fprintf("[vonfreyPreBuff] copied touched h5 file(s).\n");
    end

    % ── Apply: in-place +advanceSamp on the FLAT dataset ────────────────────
    % These event indices live as a flat dataset at h5_root/<dfID> (see
    % dtsIO_readHDF5's tryReadFlatDataset), NOT the group+/df layout that
    % dtsIO_writeDF(_toHDF5) writes. We only change the VALUE, not the shape, so
    % write straight into the existing dataset — no delete/create — which both
    % matches the flat layout and can't corrupt the object header.
    for i = 1:height(changes)
        r    = changes.row(i);
        dfID = changes.dfID(i);
        old  = readIdx(nexon, dfID, r);
        if isempty(old) || any(isnan(old)), continue; end
        writeFlatIdxHDF5(nexon, dfID, r, old + advanceSamp);
    end
    fprintf("[vonfreyPreBuff] wrote %d shifted cell(s) across %d row(s).\n", ...
            height(changes), numel(report.rowsShifted));

    % ── Verify: re-read each and confirm the exact shift ────────────────────
    verifyOK = true;
    for i = 1:height(changes)
        got = readIdx(nexon, changes.dfID(i), changes.row(i));
        if ~isequal(got, changes.new{i})
            verifyOK = false;
            fprintf("[vonfreyPreBuff] VERIFY FAIL row %d dfID %s: expected %s got %s\n", ...
                changes.row(i), changes.dfID(i), mat2str(changes.new{i}), mat2str(got));
        end
    end
    report.verifyOK = verifyOK;
    if verifyOK
        fprintf("[vonfreyPreBuff] VERIFY OK — all %d cell(s) shifted by exactly %d. Undo via change-log: %s\n", ...
                height(changes), advanceSamp, report.changeLogPath);
    else
        fprintf("[vonfreyPreBuff] VERIFY FAILED — undo using the change-log: %s\n", report.changeLogPath);
    end
end

% ── helpers ──────────────────────────────────────────────────────────────────

function v = getOpt(opts, name, default)
    if isfield(opts, name) && ~isempty(opts.(name)), v = opts.(name); else, v = default; end
end

function writeFlatIdxHDF5(nexon, dfID, r, newVal)
% Overwrite, IN PLACE, the value of the flat dataset stored at h5_root/<dfID>
% (the layout these event indices use). Only the value changes — same shape,
% same type — so we H5D.write into the existing dataset with no delete/create.
% Routes to the dfID-specific patch file if one exists (mirrors the reader).
% Falls back to h5_root/<dfID>/df if a dfID happens to use the group layout.
    DTS  = nexon.console.BASE.DTS;
    dfID = char(dfID);
    specificPathCol = sprintf('h5_path_%s', dfID);
    if ismember(specificPathCol, DTS.Properties.VariableNames)
        h5File = char(DTS.(specificPathCol)(r));
    else
        h5File = char(DTS.h5_path(r));
    end
    h5Root   = char(DTS.h5_root(r));
    flatPath = [h5Root '/' dfID];

    fapl = H5P.create('H5P_FILE_ACCESS');
    H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
    fid = H5F.open(h5File, 'H5F_ACC_RDWR', fapl);
    H5P.close(fapl);
    try
        % Prefer the flat dataset; if dfID is a group, target its /df child.
        did = [];
        try, did = H5D.open(fid, flatPath); catch, end
        if isempty(did)
            did = H5D.open(fid, [flatPath '/df']);
        end
        % Match the dataset's dataspace so H5S_ALL/H5S_ALL is a valid full write.
        sid = H5D.get_space(did);
        [~, dims] = H5S.get_simple_extent_dims(sid);
        H5S.close(sid);
        if isempty(dims)                         % scalar dataspace
            v = double(newVal(1));
        else
            v = reshape(double(newVal), fliplr(double(dims)));  % C-order → MATLAB
        end
        H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', v);
        H5D.close(did);
    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);
end

function val = readIdx(nexon, dfID, r)
% Read one trial's event index value from its DF (HDF5-backed). Returns [] if
% the trial has no such dfID, NaN-free numeric otherwise.
    val = [];
    try
        DF = dtsIO_readDF(nexon, dfID, r);
        if isstruct(DF) && isfield(DF,'df') && ~isempty(DF.df)
            val = double(DF.df(:)');
        end
    catch
    end
end

function val = rowOnsetValue(nexon, r, onsetCol, eventCols, allDFIDs)
% Per-row discriminator: the onset marker if present, else the row's min event
% index (earliest event ~ nearest the prebuffer boundary).
    val = NaN;
    if ismember(onsetCol, allDFIDs)
        v = readIdx(nexon, onsetCol, r);
        if ~isempty(v) && ~any(isnan(v)), val = min(v); return; end
    end
    mins = [];
    for c = 1:numel(eventCols)
        v = readIdx(nexon, eventCols(c), r);
        if ~isempty(v) && ~any(isnan(v)), mins(end+1) = min(v); end %#ok<AGROW>
    end
    if ~isempty(mins), val = min(mins); end
end

function s = safeStr(DTS, r, col)
    s = "";
    try
        v = DTS.(char(col));
        if iscell(v), s = string(v{r}); else, s = string(v(r)); end
    catch
    end
end

function n = safeNum(DTS, r, col)
    n = NaN;
    try
        v = DTS.(char(col));
        if iscell(v), n = double(v{r}); else, n = double(v(r)); end
    catch
    end
end
