function dtsIO_writeDF_toHDF5(h5File, h5Root, DFID, DF)
% Write one DF struct into an HDF5 file under h5Root/DFID/.
% Writes df array, axis arrays, and args.
% Shared by dtsIO_writeHDF5 and nexus_exportDTS.
%
% Chunking: if DF.ptr is present (set by nex_initAxisPointer_v2), datasets
% are written with per-axis chunk sizes and a dim_order attribute so the
% read path can do ptr-based hyperslab reads without loading full trials.
%
% Chunk targets per axis: t→256, f→32, chans→32; all others→full dimension.
% dim_order attribute format: "ax1,ax2,..." in MATLAB dimension order (1-indexed).
%
% File handle strategy: opens the HDF5 file exactly once per call using
% H5F_CLOSE_STRONG, threads fid to all low-level writes, closes once at end.
% This prevents the fd leak from h5create/h5write each opening the file
% independently (which hits Linux ulimit after ~1000 accumulated opens).

    axisKeyWords = ["f","t","chans","factor","dropout","latent","peak","param","unit","wf","measure"];
    [chunkSz, dimOrder] = dfChunkSpec(DF);

    fapl = H5P.create('H5P_FILE_ACCESS');
    H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
    % Create file on first write; open RDWR on subsequent writes.
    % nexTract routes each dfColumn to its own sibling file so there is no
    % shared-inode conflict with concurrent RDONLY sessions on the source file.
    if ~exist(h5File, 'file')
        fid = H5F.create(h5File, 'H5F_ACC_TRUNC', 'H5P_DEFAULT', fapl);
    else
        fid = H5F.open(h5File, 'H5F_ACC_RDWR', fapl);
    end
    H5P.close(fapl);

    try
        if isfield(DF, 'df') && ~isempty(DF.df)
            if ~isreal(DF.df)
                dset_re = [h5Root '/' DFID '/df_re'];
                dset_im = [h5Root '/' DFID '/df_im'];
                h5writeLL(fid, dset_re, double(real(DF.df)), chunkSz);
                h5writeLL(fid, dset_im, double(imag(DF.df)), chunkSz);
                if ~isempty(dimOrder)
                    h5writeAttLL(fid, dset_re, 'dim_order', dimOrder);
                    h5writeAttLL(fid, dset_im, 'dim_order', dimOrder);
                end
            else
                dset = [h5Root '/' DFID '/df'];
                h5writeLL(fid, dset, double(DF.df), chunkSz);
                if ~isempty(dimOrder)
                    h5writeAttLL(fid, dset, 'dim_order', dimOrder);
                end
            end
        end

        if isfield(DF, 'ax')
            axFields = fieldnames(DF.ax);
            for k = 1:numel(axFields)
                suf = axFields{k};
                val = DF.ax.(suf);
                if isempty(val), continue; end
                if isnumeric(val) && any(strcmp(axisKeyWords, suf))
                    h5writeLL(fid, [h5Root '/' DFID '/' suf], double(val), []);
                elseif isstring(val) || iscellstr(val)
                    h5writeStringSafe(fid, [h5Root '/' DFID '/' suf], val);
                end
            end
        end

        if isfield(DF, 'args') && isnumeric(DF.args) && ~isempty(DF.args)
            h5writeLL(fid, [h5Root '/' DFID '/args'], double(DF.args), []);
        end
    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);
end

% ── Helpers ───────────────────────────────────────────────────────────────

function [chunkSz, dimOrder] = dfChunkSpec(DF, chunkTargetBytes)
% Derive ChunkSize vector and dim_order string from DF.ptr.
% Returns [] / '' if DF has no ptr or no df.
%
% chunkTargetBytes : target bytes per chunk (default 128*1024 = 128 KB).
%   Every axis present in DF.ptr is chunked. The budget is distributed
%   across chunked dimensions smallest-first: small dims saturate at their
%   full size and the remaining budget flows to larger dims, keeping total
%   chunk size near the target regardless of how many axes are chunked.
    if nargin < 2 || isempty(chunkTargetBytes), chunkTargetBytes = 128*1024; end
    chunkSz  = [];
    dimOrder = '';
    if ~isfield(DF,'df') || isempty(DF.df), return; end
    if ~isfield(DF,'ptr') || isempty(DF.ptr), return; end

    ptr  = DF.ptr;
    dfSz = size(DF.df);
    ndim = numel(dfSz);
    cSz     = dfSz;
    axNames = repmat({''}, 1, ndim);

    if isa(ptr, 'nexObj_ptr')
        pFields = properties(ptr);
    else
        pFields = fieldnames(ptr);
    end

    axDims  = [];
    axSizes = [];
    for i = 1:numel(pFields)
        ax  = pFields{i};
        dim = ptr.(ax).dim;
        if ~isscalar(dim) || dim < 1 || dim > ndim, continue; end
        axDims(end+1)  = dim;   %#ok<AGROW>
        axSizes(end+1) = dfSz(dim); %#ok<AGROW>
        axNames{dim}   = ax;
    end

    if ~isempty(axDims)
        cSz = budgetChunkSz(dfSz, axDims, axSizes, chunkTargetBytes);
    end

    chunkSz = cSz;
    if all(~cellfun('isempty', axNames))
        dimOrder = strjoin(axNames, ',');
    end
end

function cSz = budgetChunkSz(dfSz, axDims, axSizes, chunkTargetBytes)
    cSz          = dfSz;
    targetElems  = chunkTargetBytes / 8;
    [~, sortIdx] = sort(axSizes, 'ascend');
    budget       = targetElems;
    chunkVals    = zeros(size(axDims));
    for k = 1:numel(sortIdx)
        remaining          = numel(sortIdx) - k + 1;
        ci                 = min(axSizes(sortIdx(k)), max(1, floor(budget^(1/remaining))));
        chunkVals(sortIdx(k)) = ci;
        budget             = budget / ci;
    end
    for i = 1:numel(axDims)
        cSz(axDims(i)) = chunkVals(i);
    end
end

function h5writeLL(fid, dset, arr, chunkSz)
% Write a double array to dset using an already-open file ID.
% Creates intermediate groups automatically. Overwrites existing dataset.
    useChunk = ~isempty(chunkSz) && numel(chunkSz) == ndims(arr) && ...
               all(chunkSz >= 1) && all(chunkSz <= size(arr));

    % H5L.exists throws if any intermediate group in the path is missing;
    % treat that as non-existent (lcpl will create them on H5D.create).
    dsetExists = false;
    try, dsetExists = H5L.exists(fid, dset, 'H5P_DEFAULT'); catch, end
    if dsetExists
        H5L.delete(fid, dset, 'H5P_DEFAULT');
    end

    sz   = size(arr);
    dims = fliplr(double(sz));
    sid  = H5S.create_simple(numel(sz), dims, dims);

    dcpl = H5P.create('H5P_DATASET_CREATE');
    if useChunk
        H5P.set_chunk(dcpl, fliplr(double(chunkSz)));
    end
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);

    did = H5D.create(fid, dset, 'H5T_NATIVE_DOUBLE', sid, lcpl, dcpl, 'H5P_DEFAULT');
    H5P.close(lcpl);
    H5P.close(dcpl);
    H5S.close(sid);

    H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', arr);
    H5D.close(did);
end

function h5writeAttLL(fid, dset, attName, attVal)
% Write a scalar string attribute on an existing dataset using open fid.
    str = char(attVal);
    did = H5D.open(fid, dset);
    try
        try, H5A.delete(did, attName); catch, end
        atype = H5T.copy('H5T_C_S1');
        H5T.set_size(atype, max(1, numel(str)));
        H5T.set_strpad(atype, 'H5T_STR_NULLTERM');
        asid = H5S.create('H5S_SCALAR');
        aid  = H5A.create(did, attName, atype, asid, 'H5P_DEFAULT', 'H5P_DEFAULT');
        H5A.write(aid, atype, str);
        H5A.close(aid);
        H5T.close(atype);
        H5S.close(asid);
    catch ME
        H5D.close(did);
        rethrow(ME);
    end
    H5D.close(did);
end

function h5writeStringSafe(fid, dset, val)
% Write a string-valued axis as a variable-length UTF-8 string dataset.
% Uses only the low-level API so the already-open fid is never reopened
% (high-level h5create/h5write would conflict with the open fid).
    c = cellstr(val(:));
    n = numel(c);

    try
        if H5L.exists(fid, dset, 'H5P_DEFAULT')
            H5L.delete(fid, dset, 'H5P_DEFAULT');
        end
    catch
    end

    tid = H5T.copy('H5T_C_S1');
    H5T.set_size(tid, 'H5T_VARIABLE');
    H5T.set_cset(tid, 'H5T_CSET_UTF8');
    H5T.set_strpad(tid, 'H5T_STR_NULLTERM');

    sid  = H5S.create_simple(1, n, n);
    lcpl = H5P.create('H5P_LINK_CREATE');
    H5P.set_create_intermediate_group(lcpl, 1);
    did  = H5D.create(fid, dset, tid, sid, lcpl, 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5P.close(lcpl);
    H5S.close(sid);

    H5D.write(did, tid, 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', c);
    H5D.close(did);
    H5T.close(tid);
end
