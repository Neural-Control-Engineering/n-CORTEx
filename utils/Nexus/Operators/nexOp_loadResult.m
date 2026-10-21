function [T, displayLabel] = nexOp_loadResult(nexObj_or_dir, resultID)
% Load a RESULTS table from nexRESULTS.h5.
%
%   T = nexOp_loadResult(nexObj, resultID)
%   T = nexOp_loadResult('/path/to/dts/dir', resultID)
%
% ptr is reconstructed from df + ax via nexInit_axisPointer.
% Complement to nexOp_saveResult.

    if ischar(nexObj_or_dir) || isstring(nexObj_or_dir)
        h5Dir = char(nexObj_or_dir);
    else
        nexon = nexObj_or_dir.nexon;
        h5Dir = fileparts(char(nexon.console.BASE.DTS.h5_path(1)));
    end

    h5File = fullfile(h5Dir, 'nexRESULTS.h5');
    if ~isfile(h5File)
        error('nexOp_loadResult: no results file found at %s', h5File);
    end

    [T, displayLabel] = readResultsHDF5(h5File, char(resultID));
end

% ── HDF5 read ─────────────────────────────────────────────────────────────

function [T, displayLabel] = readResultsHDF5(h5File, resultID)
    % resultID is guaranteed char — all path concatenations stay char.
    root = ['/' resultID];

    fapl = H5P.create('H5P_FILE_ACCESS');
    H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
    fid = H5F.open(h5File, 'H5F_ACC_RDONLY', fapl);
    H5P.close(fapl);

    try
        rootExists = false;
        try, rootExists = H5L.exists(fid, root, 'H5P_DEFAULT'); catch, end
        if ~rootExists
            H5F.close(fid);
            error('nexOp_loadResult: resultID "%s" not found in %s', resultID, h5File);
        end

        nRows = double(h5readNumLL(fid, [root '/nRows']));

        % Display label (written by nexOp_saveResult; absent in older files)
        displayLabel = '';
        try
            hasLabel = false;
            try, hasLabel = H5L.exists(fid, [root '/meta/displayLabel'], 'H5P_DEFAULT'); catch, end
            if hasLabel
                displayLabel = char(h5readStrLL(fid, [root '/meta/displayLabel']));
            end
        catch
        end

        % Grouping column metadata
        grpCols = {};
        grpData = struct();
        hasGC   = false;
        try, hasGC = H5L.exists(fid, [root '/meta/groupCols'], 'H5P_DEFAULT'); catch, end
        if hasGC
            grpCols = cellstr(h5readStrLL(fid, [root '/meta/groupCols']));
            for ci = 1:numel(grpCols)
                col          = grpCols{ci};
                grpData.(col) = h5readStrLL(fid, [root '/meta/' col]);
            end
        end

        % Per-row data
        df_out  = cell(nRows, 1);
        sem_out = cell(nRows, 1);
        ax_out  = cell(nRows, 1);
        ptr_out = cell(nRows, 1);
        % W/ax_W/ptr_W/featureLabels: mdlObj RESULTS' weights facet
        % (Nexus WIP.md #11) — stay empty (not extra columns at all,
        % until at least one row actually has one below) for a plain
        % nexObject-saved file, which never wrote these groups.
        W_out = cell(nRows, 1); axW_out = cell(nRows, 1); ptrW_out = cell(nRows, 1);
        featureLabels_out = cell(nRows, 1);
        anyW = false; anyFeatureLabels = false;

        for ri = 1:nRows
            rowPath = sprintf('%s/row_%04d', root, ri - 1);

            % df (real or complex)
            hasRe = false;  hasIm = false;
            try, hasRe = H5L.exists(fid, [rowPath '/df_re'], 'H5P_DEFAULT'); catch, end
            try, hasIm = H5L.exists(fid, [rowPath '/df_im'], 'H5P_DEFAULT'); catch, end
            if hasRe && hasIm
                df_out{ri} = complex(h5readNumLL(fid, [rowPath '/df_re']), ...
                                     h5readNumLL(fid, [rowPath '/df_im']));
            else
                df_out{ri} = h5readNumLL(fid, [rowPath '/df']);
            end

            % sem
            hasSem = false;
            try, hasSem = H5L.exists(fid, [rowPath '/sem'], 'H5P_DEFAULT'); catch, end
            sem_out{ri} = zeros(size(df_out{ri}));
            if hasSem
                sem_out{ri} = h5readNumLL(fid, [rowPath '/sem']);
            end

            % ax fields
            ax_out{ri} = readAxGroup(fid, [rowPath '/ax']);

            % Reconstruct ptr from df + ax (ptr is never stored)
            try
                ptr_out{ri} = nexInit_axisPointer(df_out{ri}, ax_out{ri});
            catch
                ptr_out{ri} = [];
            end

            % W / ax_W (mdlObj weights facet — present only if this row
            % was saved from an mdlObj RESULTS table with a weights fit).
            hasWRe = false; hasWIm = false; hasWPlain = false;
            try, hasWRe    = H5L.exists(fid, [rowPath '/W_re'], 'H5P_DEFAULT'); catch, end
            try, hasWIm    = H5L.exists(fid, [rowPath '/W_im'], 'H5P_DEFAULT'); catch, end
            try, hasWPlain = H5L.exists(fid, [rowPath '/W'],    'H5P_DEFAULT'); catch, end
            if hasWRe && hasWIm
                W_out{ri} = complex(h5readNumLL(fid, [rowPath '/W_re']), ...
                                     h5readNumLL(fid, [rowPath '/W_im']));
                anyW = true;
            elseif hasWPlain
                W_out{ri} = h5readNumLL(fid, [rowPath '/W']);
                anyW = true;
            end
            axW_out{ri} = readAxGroup(fid, [rowPath '/ax_W']);
            if ~isempty(fieldnames(axW_out{ri})), anyW = true; end
            % ptr_W is never stored — reconstruct from W + ax_W exactly
            % like ptr from df + ax, via the SAME v2 initializer cvPermute
            % originally built ax_W's pointer with (ordinary
            % nexInit_axisPointer doesn't know about ax_W's coIdx-eligible
            % fields — WIP.md #11).
            if anyW && ~isempty(W_out{ri})
                try
                    Rw = nex_initAxisPointer_v2(struct('df', W_out{ri}, 'ax', axW_out{ri}));
                    ptrW_out{ri} = Rw.ptr;
                catch
                    ptrW_out{ri} = [];
                end
            end

            % featureLabels (2-D string matrix, flattened on save)
            hasFL = false;
            try, hasFL = H5L.exists(fid, [rowPath '/featureLabels'], 'H5P_DEFAULT'); catch, end
            if hasFL
                flFlat = h5readStrLL(fid, [rowPath '/featureLabels']);
                flShape = h5readNumLL(fid, [rowPath '/featureLabels_shape']);
                featureLabels_out{ri} = reshape(flFlat, flShape(1), flShape(2));
                anyFeatureLabels = true;
            end
        end
    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);

    % Assemble RESULTS table (structural cols first, then grouping cols).
    % W/ax_W/ptr_W/featureLabels only added as real columns when at least
    % one row actually had them — an mdlObj-saved file gets them, a plain
    % nexObject-saved file doesn't grow extra all-empty columns.
    T = table(df_out, ax_out, ptr_out, sem_out, 'VariableNames', {'df','ax','ptr','sem'});
    if anyW
        T.W     = W_out;
        T.ax_W  = axW_out;
        T.ptr_W = ptrW_out;
    end
    if anyFeatureLabels
        T.featureLabels = featureLabels_out;
    end
    for ci = 1:numel(grpCols)
        col     = grpCols{ci};
        T.(col) = grpData.(col);
    end
end

function ax = readAxGroup(fid, groupPath)
% Field-by-field reader shared by 'ax' and 'ax_W' groups — returns
% struct() (not an error) when the group doesn't exist for this row.
    ax = struct();
    hasGroup = false;
    try, hasGroup = H5L.exists(fid, groupPath, 'H5P_DEFAULT'); catch, end
    if ~hasGroup, return; end
    gid  = H5G.open(fid, char(groupPath));
    info = H5G.get_info(gid);
    for ai = 0:double(info.nlinks) - 1
        fn    = H5L.get_name_by_idx(gid, '.', 'H5_INDEX_NAME', 'H5_ITER_INC', ai, 'H5P_DEFAULT');
        dpath = char([groupPath '/' fn]);
        did   = H5D.open(fid, dpath);
        tid   = H5D.get_type(did);
        cls   = H5T.get_class(tid);
        H5T.close(tid);
        H5D.close(did);
        if strcmp(cls, 'H5T_STRING')
            ax.(fn) = h5readStrLL(fid, dpath);
        else
            ax.(fn) = h5readNumLL(fid, dpath);
        end
    end
    H5G.close(gid);
end

% ── Low-level helpers ─────────────────────────────────────────────────────

function val = h5readNumLL(fid, dsetPath)
% Read a numeric dataset (full read, returns double).
    did  = H5D.open(fid, char(dsetPath));
    fsid = H5D.get_space(did);
    val  = H5D.read(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5S.close(fsid);
    H5D.close(did);
    if iscell(val)
        % A variable-length (or cell-wrapped-at-write-time -- same
        % storage pattern found in the registry's regMap.Y) numeric
        % dataset decodes to a cell here instead of a plain array.
        % cell2mat recovers the plain array whenever every element is
        % uniform (the common case for axis data); if genuinely ragged,
        % keep the cell rather than erroring -- forcing double() on that
        % would silently corrupt whichever row has a different length.
        try
            val = cell2mat(val);
        catch
            return;
        end
    end
    val  = double(val);
end

function val = h5readStrLL(fid, dsetPath)
% Read a variable-length string dataset using low-level API.
    did = H5D.open(fid, char(dsetPath));
    tid = H5D.get_type(did);
    val = H5D.read(did, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5T.close(tid);
    H5D.close(did);
    if iscell(val), val = string(val(:)); end
    if ischar(val), val = string(val);    end
end
