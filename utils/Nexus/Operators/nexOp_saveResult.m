function h5File = nexOp_saveResult(nexObj, resultID)
% Save nexObj.RESULTS.(resultID) to nexRESULTS.h5 alongside the DTS.
%
%   h5File = nexOp_saveResult(nexObj, resultID)
%
% Layout:  {dtsDir}/nexRESULTS.h5  →  /{resultID}/row_NNNN/{df,sem,ax/*}
%                                      /{resultID}/meta/{groupCols,colName,...}
%
% ptr is NOT saved — it is always reconstructed from df+ax on load.
% Overwrites any previously saved entry with the same resultID.
% Returns '' when DTS is not disk-backed or RESULTS is empty.

    nexon = nexObj.nexon;
    if ~ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames)
        warning('nexOp_saveResult: DTS is not disk-backed; save skipped.');
        h5File = '';
        return;
    end
    if ~isfield(nexObj.RESULTS, resultID) || isempty(nexObj.RESULTS.(resultID))
        warning('nexOp_saveResult: RESULTS.%s is empty.', resultID);
        h5File = '';
        return;
    end

    h5Dir  = fileparts(char(nexon.console.BASE.DTS.h5_path(1)));
    h5File = fullfile(h5Dir, 'nexRESULTS.h5');

    T = nexObj.RESULTS.(resultID);
    displayLabel = '';
    try
        if isfield(nexObj.resultLabels, resultID)
            displayLabel = char(nexObj.resultLabels.(resultID));
        end
    catch
    end
    writeResultsHDF5(h5File, char(resultID), T, displayLabel);
    fprintf('nexOp_saveResult: %d rows → %s [/%s]\n', height(T), h5File, resultID);
end

% ── HDF5 write ────────────────────────────────────────────────────────────

function writeResultsHDF5(h5File, resultID, T, displayLabel)
    % resultID is guaranteed char here — all path concatenations stay char.
    % W/ax_W/featureLabels are mdlObj RESULTS-specific (cvPermute's weight
    % facet, Nexus WIP.md #11) — never present on a plain nexObject
    % RESULTS row, so excluding them here is a no-op for every existing
    % caller. ptr_W is skipped like ptr (reconstructed from W+ax_W on
    % load). fitSentinel is NOT persisted at all — canonReg can be a
    % containers.Map (fit-time projection state, not analysis output);
    % round-tripping it isn't needed for anything this save/load pair is
    % for, and silently mis-serializing a Map via string() would be worse
    % than just not saving it.
    structCols = {'df','ax','ptr','sem','W','ax_W','ptr_W','fitSentinel','featureLabels'};
    grpCols    = setdiff(T.Properties.VariableNames, structCols, 'stable');
    nRows      = height(T);
    hasSem           = ismember('sem', T.Properties.VariableNames);
    hasW             = ismember('W', T.Properties.VariableNames);
    hasAxW           = ismember('ax_W', T.Properties.VariableNames);
    hasFeatureLabels = ismember('featureLabels', T.Properties.VariableNames);

    fapl = H5P.create('H5P_FILE_ACCESS');
    H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
    if ~isfile(h5File)
        fid = H5F.create(h5File, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', fapl);
    else
        fid = H5F.open(h5File, 'H5F_ACC_RDWR', fapl);
    end
    H5P.close(fapl);

    try
        root = ['/' resultID];   % char

        % Remove existing group so this is a clean overwrite.
        existsRoot = false;
        try, existsRoot = H5L.exists(fid, root, 'H5P_DEFAULT'); catch, end
        if existsRoot
            H5L.delete(fid, root, 'H5P_DEFAULT');
        end

        % nRows scalar — LCPL creates the /{resultID}/ group automatically.
        h5writeLL(fid, [root '/nRows'], double(nRows), []);

        % Display label (human-readable, survives save/load cycle).
        if nargin >= 4 && ~isempty(displayLabel)
            h5writeStrLL(fid, [root '/meta/displayLabel'], string(displayLabel));
        end

        % Source dfID — used by discoverResults to scope results to the right object.
        try
            dfid = char(nexObj.dfID_source);
            if ~isempty(dfid)
                h5writeStrLL(fid, [root '/meta/dfID_source'], string(dfid));
            end
        catch
        end

        % Grouping column metadata (all pure low-level, no h5create/h5write).
        if ~isempty(grpCols)
            h5writeStrLL(fid, [root '/meta/groupCols'], string(grpCols(:)));
            for ci = 1:numel(grpCols)
                col  = grpCols{ci};
                vals = string(T.(col));
                h5writeStrLL(fid, [root '/meta/' col], vals(:));
            end
        end

        % Per-row data.
        for ri = 1:nRows
            rowPath = sprintf('%s/row_%04d', root, ri - 1);
            df  = T.df{ri};
            ax  = T.ax{ri};

            if ~isreal(df)
                h5writeLL(fid, [rowPath '/df_re'], double(real(df)), []);
                h5writeLL(fid, [rowPath '/df_im'], double(imag(df)), []);
            else
                h5writeLL(fid, [rowPath '/df'], double(df), []);
            end

            if hasSem
                sem = T.sem{ri};
                if ~isempty(sem)
                    h5writeLL(fid, [rowPath '/sem'], double(sem), []);
                end
            end

            if ~isempty(ax)
                writeAxStruct(fid, [rowPath '/ax'], ax);
            end

            % W/ax_W: mdlObj RESULTS' weights facet (Nexus WIP.md #11) —
            % same df/ax pattern, own sub-path so a plain nexObject row
            % (neither column present) writes nothing extra.
            if hasW
                W = T.W{ri};
                if ~isempty(W)
                    if ~isreal(W)
                        h5writeLL(fid, [rowPath '/W_re'], double(real(W)), []);
                        h5writeLL(fid, [rowPath '/W_im'], double(imag(W)), []);
                    else
                        h5writeLL(fid, [rowPath '/W'], double(W), []);
                    end
                end
            end
            if hasAxW
                axW = T.ax_W{ri};
                if ~isempty(axW)
                    writeAxStruct(fid, [rowPath '/ax_W'], axW);
                end
            end
            if hasFeatureLabels
                fl = T.featureLabels{ri};
                if ~isempty(fl)
                    % h5writeStrLL only takes 1-D — flatten column-major
                    % and store the shape alongside so reshape() on load
                    % recovers the real [nFeatures x nSwp] matrix.
                    h5writeLL(fid, [rowPath '/featureLabels_shape'], double(size(fl)), []);
                    h5writeStrLL(fid, [rowPath '/featureLabels'], string(fl(:)));
                end
            end
        end
    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);
end

function writeAxStruct(fid, groupPath, ax)
% Field-by-field writer shared by 'ax' and 'ax_W' — same per-field
% numeric/string branch, just parameterized on the destination group.
    axFs = fieldnames(ax);
    for ai = 1:numel(axFs)
        fn  = axFs{ai};
        val = ax.(fn);
        if isnumeric(val) && ~isempty(val)
            h5writeLL(fid, [groupPath '/' fn], double(val), []);
        elseif (isstring(val) || iscellstr(val)) && ~isempty(val)
            h5writeStrLL(fid, [groupPath '/' fn], string(val(:)));
        end
    end
end

% ── Low-level helpers ─────────────────────────────────────────────────────

function h5writeLL(fid, dset, arr, chunkSz)
% Write a double array. dset may be char or string — char() is applied inside.
    dset     = char(dset);
    useChunk = ~isempty(chunkSz) && numel(chunkSz) == ndims(arr) && ...
               all(chunkSz >= 1) && all(chunkSz <= size(arr));
    dsetExists = false;
    try, dsetExists = H5L.exists(fid, dset, 'H5P_DEFAULT'); catch, end
    if dsetExists, H5L.delete(fid, dset, 'H5P_DEFAULT'); end

    sz   = size(arr);
    dims = fliplr(double(sz));
    sid  = H5S.create_simple(numel(sz), dims, dims);
    dcpl = H5P.create('H5P_DATASET_CREATE');
    if useChunk, H5P.set_chunk(dcpl, fliplr(double(chunkSz))); end
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did  = H5D.create(fid, dset, 'H5T_NATIVE_DOUBLE', sid, lcpl, dcpl, 'H5P_DEFAULT');
    H5P.close(lcpl); H5P.close(dcpl); H5S.close(sid);
    H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', arr);
    H5D.close(did);
end

function h5writeStrLL(fid, dset, vals)
% Write a string array using pure low-level HDF5 (variable-length strings).
% Avoids h5create/h5write so there is no second file-open while fid is live.
    dset = char(dset);
    c    = reshape(cellstr(string(vals)), 1, []);   % always 1×N cell of char
    N    = numel(c);
    if N == 0, return; end

    vls_t = H5T.copy('H5T_C_S1');
    H5T.set_size(vls_t, 'H5T_VARIABLE');
    H5T.set_strpad(vls_t, 'H5T_STR_NULLTERM');

    sid  = H5S.create_simple(1, double(N), double(N));
    dcpl = H5P.create('H5P_DATASET_CREATE');
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did  = H5D.create(fid, dset, vls_t, sid, lcpl, dcpl, 'H5P_DEFAULT');
    H5P.close(lcpl); H5P.close(dcpl); H5S.close(sid);

    H5D.write(did, vls_t, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', c);
    H5D.close(did);
    H5T.close(vls_t);
end
