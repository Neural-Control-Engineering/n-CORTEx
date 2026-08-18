function nSunk = nexDTS_sinkInMemory(nexon, dtsPath)
% Flush in-memory (hybrid) DTS rows to the disk-backed store, HEADLESSLY.
%
%   nSunk = nexDTS_sinkInMemory(nexon)          % derive DTS dir from the manifest
%   nSunk = nexDTS_sinkInMemory(nexon, dtsPath) % explicit DTS directory
%
% Shared sink core behind the npxls control panel's "Sink to Disk" button and
% the target app's close handler: append the in-memory capture rows
% (h5_path == "") into the existing nexDTS store and re-point the DTS at the
% resulting manifest. No dialogs — reports via fprintf/warning so it is safe to
% call during teardown.
%
% Returns: number of rows sunk; 0 = nothing to sink (no nexon / fully disk-backed);
%          -1 = aborted or failed (nothing written, source rows preserved).
%
% dtsPath: the DTS DIRECTORY (holding nexDTS.h5 + nexDTS_manifest.mat). Omitted
% or empty → derived from the first disk-backed row's h5_path folder, so a hybrid
% DTS that already has disk rows needs no path argument.

    nSunk = 0;
    if isempty(nexon) || ~isa(nexon, 'Nexon'), return; end     % struct placeholder → skip

    DTS_inmem = nexon.console.BASE.DTS;
    if isempty(DTS_inmem) || ~istable(DTS_inmem) || height(DTS_inmem) == 0
        return;
    end

    % Only the in-memory rows (h5_path == "") need sinking; a fully disk-backed
    % DTS has nothing to flush.
    hasH5 = ismember('h5_path', DTS_inmem.Properties.VariableNames);
    nToSink = height(DTS_inmem);
    if hasH5
        nToSink = nnz(strlength(string(DTS_inmem.h5_path)) == 0);
        if nToSink == 0, return; end
    end

    % Resolve the DTS directory: explicit arg, else the folder of an existing
    % disk-backed row's h5_path.
    if nargin < 2, dtsPath = ''; end
    dtsPath = char(string(dtsPath));
    if isempty(dtsPath) && hasH5
        diskRow = find(strlength(string(DTS_inmem.h5_path)) > 0, 1);
        if ~isempty(diskRow)
            dtsPath = fileparts(char(DTS_inmem.h5_path(diskRow)));
        end
    end
    if isempty(dtsPath)
        warning("nexDTS_sinkInMemory:noPath", ...
            "no DTS directory (none passed and no disk-backed row to derive from) — %d row(s) NOT sunk", nToSink);
        nSunk = -1; return;
    end

    try
        [h5File, manifest] = nexDTS_openOrCreate(dtsPath);
        % Data-loss guard: sinking a hybrid DTS needs the existing manifest so the
        % already-disk rows survive the combine. Abort rather than drop them.
        if hasH5 && (isempty(manifest) || ~istable(manifest))
            warning("nexDTS_sinkInMemory:noManifest", ...
                "existing manifest not found at %s — aborting to avoid dropping disk rows", dtsPath);
            nSunk = -1; return;
        end
        manifest = nexDTS_appendRows(DTS_inmem, h5File, manifest, nexon, dtsPath);
        save(fullfile(dtsPath, 'nexDTS_manifest.mat'), 'manifest');
        nexon.console.BASE.DTS = manifest;
        try, nexon.console.BASE.updateControlPanel(); catch, end
        nSunk = nToSink;
        fprintf("nexDTS_sinkInMemory: sunk %d row(s) to %s\n", nSunk, dtsPath);
    catch e
        disp(getReport(e));
        nSunk = -1;
    end
end
