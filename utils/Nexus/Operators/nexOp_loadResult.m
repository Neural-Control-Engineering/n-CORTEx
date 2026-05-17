function T = nexOp_loadResult(nexObj_or_dir, resultID)
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

    T = readResultsHDF5(h5File, char(resultID));
end

% ── HDF5 read ─────────────────────────────────────────────────────────────

function T = readResultsHDF5(h5File, resultID)
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
            ax    = struct();
            hasAx = false;
            try, hasAx = H5L.exists(fid, [rowPath '/ax'], 'H5P_DEFAULT'); catch, end
            if hasAx
                axGid  = H5G.open(fid, char([rowPath '/ax']));
                axInfo = H5G.get_info(axGid);
                for ai = 0:double(axInfo.nlinks) - 1
                    fn    = H5L.get_name_by_idx(axGid, '.', 'H5_INDEX_NAME', 'H5_ITER_INC', ai, 'H5P_DEFAULT');
                    dpath = char([rowPath '/ax/' fn]);
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
                H5G.close(axGid);
            end
            ax_out{ri} = ax;

            % Reconstruct ptr from df + ax (ptr is never stored)
            try
                ptr_out{ri} = nexInit_axisPointer(df_out{ri}, ax);
            catch
                ptr_out{ri} = [];
            end
        end
    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);

    % Assemble RESULTS table (structural cols first, then grouping cols)
    T = table(df_out, ax_out, ptr_out, sem_out, 'VariableNames', {'df','ax','ptr','sem'});
    for ci = 1:numel(grpCols)
        col     = grpCols{ci};
        T.(col) = grpData.(col);
    end
end

% ── Low-level helpers ─────────────────────────────────────────────────────

function val = h5readNumLL(fid, dsetPath)
% Read a numeric dataset (full read, returns double).
    did  = H5D.open(fid, char(dsetPath));
    fsid = H5D.get_space(did);
    val  = H5D.read(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5S.close(fsid);
    H5D.close(did);
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
