function manifest_out = nexDTS_appendRows(DTS_inmem, h5File, manifest_in, nexon, patchDir, overwrite)
% Write new rows from DTS_inmem into the nexDTS HDF5, return updated manifest.
%
%   DTS_inmem    : in-memory table of rows to sink (no h5_path column).
%                  May be a hybrid DTS — only rows with h5_path=="" are processed.
%   h5File       : path to the nexDTS HDF5 (from nexDTS_openOrCreate).
%   manifest_in  : existing manifest table, or [] on first sink.
%   nexon        : (optional) live Nexon handle — required for patch routing.
%   patchDir     : (optional) directory for newly-created patch HDF5 files.
%                  Defaults to the directory containing h5File.
%   overwrite    : (optional, default false) when true, skip deduplication and
%                  replace existing manifest rows for matching trials so that
%                  re-extraction updates already-written HDF5 data in place.
%
% Patch routing (when nexon is supplied):
%   Columns registered as pending patches or already having h5_path_<dfID>
%   in manifest_in are routed to dedicated HDF5 files by nexDTS_sinkPatchCols.
%   The remaining columns go into the main h5File via nexus_exportDTS.
%
% Deduplication key: sessionLabel + trialNumber.
% Returns combined manifest (old rows + new rows, or replaced rows if overwrite).

    if nargin < 4, nexon     = []; end
    if nargin < 5, patchDir  = fileparts(h5File); end
    if nargin < 6, overwrite = false; end

    manifest_out = manifest_in;
    if isempty(DTS_inmem) || ~istable(DTS_inmem), return; end

    % ── If given a hybrid DTS, extract only the in-memory rows ───────────
    if ismember('h5_path', DTS_inmem.Properties.VariableNames)
        h5paths   = string(DTS_inmem.h5_path);
        isInMem   = strlength(h5paths) == 0;
        DTS_inmem = removevars(DTS_inmem(isInMem, :), {'h5_path','h5_root'});
        if height(DTS_inmem) == 0, return; end
    end

    % ── Deduplicate: skip rows already in manifest ────────────────────────
    if ~overwrite && ~isempty(manifest_in) && istable(manifest_in) && ...
            ismember('sessionLabel', manifest_in.Properties.VariableNames)
        existKeys = string(manifest_in.sessionLabel) + "_" + ...
                    string(manifest_in.trialNumber);
        newKeys   = string(DTS_inmem.sessionLabel)   + "_" + ...
                    string(DTS_inmem.trialNumber);
        DTS_inmem = DTS_inmem(~ismember(newKeys, existKeys), :);
        if height(DTS_inmem) == 0, return; end
    end

    % ── Split off patch-eligible columns ─────────────────────────────────
    if ~isempty(nexon)
        DTS_inmem = nexDTS_sinkPatchCols(DTS_inmem, manifest_in, nexon, patchDir);
    end

    % ── Write remaining columns to the main nexDTS HDF5 ──────────────────
    % Guard: if only address columns remain after patch split, nothing to write
    nonAddrCols = setdiff(DTS_inmem.Properties.VariableNames, ...
                          {'sessionLabel','trialNumber','signal_types'});
    if isempty(nonAddrCols), return; end

    manifest_new = nexus_exportDTS(DTS_inmem, h5File);

    if isempty(manifest_in)
        manifest_out = manifest_new;
    elseif overwrite && ~isempty(manifest_new)
        existKeys = string(manifest_in.sessionLabel) + "_" + string(manifest_in.trialNumber);
        newKeys   = string(manifest_new.sessionLabel) + "_" + string(manifest_new.trialNumber);
        manifest_out = [manifest_in(~ismember(existKeys, newKeys), :); manifest_new];
    else
        manifest_out = [manifest_in; manifest_new];
    end
end
