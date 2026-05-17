function DF = dtsIO_readHDF5(DTS, DFID, dtsIdx, ptr)
% Read a DF struct from HDF5 for one or more manifest rows.
% Internal helper called by dtsIO_composeDF when DTS is disk-backed.
%
%   dtsIdx : scalar integer, logical vector, or numeric vector of row indices
%   ptr    : optional — plain struct or nexObj_ptr with .(axName).range = [i1,i2].
%            When provided and the dataset has a dim_order attribute, only the
%            hyperslab defined by the ptr ranges is read from disk.
%            Axes with full-range or absent ptr entries are loaded completely.
%            Falls back to full read for legacy datasets without dim_order.

    if nargin < 4, ptr = []; end
    axisKeyWords = ["f","t","chans","factor","dropout","latent"];

    % Convert nexObj_ptr handle to plain struct once, at the boundary.
    ptr = ptrToStruct(ptr);

    if islogical(dtsIdx)
        rows = find(dtsIdx);
    elseif isempty(dtsIdx)
        rows = find(nex_getRouterIdx(DTS));
        rows = rows(1);
        DTS  = DTS.console.BASE.DTS;
    else
        rows = dtsIdx(:)';
    end

    if isscalar(rows)
        h5File = char(DTS.h5_path(rows));
        h5Root = char(DTS.h5_root(rows));
        DF = readOneTrialHDF5(h5File, h5Root, DFID, axisKeyWords, ptr);
    else
        DF = {};
        for i = 1:numel(rows)
            h5File = char(DTS.h5_path(rows(i)));
            h5Root = char(DTS.h5_root(rows(i)));
            DF = [DF; {readOneTrialHDF5(h5File, h5Root, DFID, axisKeyWords, ptr)}]; %#ok<AGROW>
        end
    end
end

% ── Trial reader ───────────────────────────────────────────────────────────

function DF = readOneTrialHDF5(h5File, h5Root, DFID, axisKeyWords, ptr)
% Low-level single-trial HDF5 read.  Opens the file exactly once with
% H5F_CLOSE_STRONG so the OS fd is released before any subsequent write
% attempt.  Multiple h5read/h5info calls per trial were leaking RDONLY fds
% whose flock(LOCK_SH) blocked the RDWR write open in the same process.
    DF        = struct;
    groupPath = [h5Root '/' DFID];

    fapl = H5P.create('H5P_FILE_ACCESS');
    H5P.set_fclose_degree(fapl, 'H5F_CLOSE_STRONG');
    fid = H5F.open(h5File, 'H5F_ACC_RDONLY', fapl);
    H5P.close(fapl);

    try
        pathExists = false;
        try, pathExists = H5L.exists(fid, groupPath, 'H5P_DEFAULT'); catch, end
        if ~pathExists
            H5F.close(fid);
            return;
        end

        % Flat dataset — stored directly at groupPath (no sub-group).
        flatVal = tryReadFlatDataset(fid, groupPath);
        if ~isempty(flatVal)
            DF.df = flatVal;
            H5F.close(fid);
            return;
        end

        % Group — collect dataset names and their metadata.
        gid = H5G.open(fid, groupPath);
        ginfo = H5G.get_info(gid);
        numLinks = double(ginfo.nlinks);
        names = cell(1, numLinks);
        for k = 0:numLinks-1
            names{k+1} = H5L.get_name_by_idx(gid, '.', 'H5_INDEX_NAME', 'H5_ITER_INC', k, 'H5P_DEFAULT');
        end
        H5G.close(gid);

        % Build dataset info structs (for dfHyperslab / inferDimAxesFromInfo).
        dsetInfos = buildDatasetInfos(fid, groupPath, names);

        % Read dim_order attribute for hyperslab slicing.
        dimAxes = {};
        if ~isempty(ptr)
            for cand = {'df', 'df_re'}
                dpath = [groupPath '/' cand{1}];
                if ~H5L.exists(fid, dpath, 'H5P_DEFAULT'), continue; end
                dimAxes = readDimOrderAtt(fid, dpath);
                if ~isempty(dimAxes), break; end
            end
            if isempty(dimAxes)
                dimAxes = inferDimAxesFromInfo(dsetInfos, axisKeyWords);
            end
        end

        % Read each dataset.
        for k = 1:numel(names)
            suffix   = names{k};
            dsetPath = [groupPath '/' suffix];
            info_k   = dsetInfos(k);
            isStrDset = strcmp(info_k.Datatype.Class, 'H5T_STRING');

            if any(strcmp({'df','df_re','df_im'}, suffix))
                [hs_start, hs_count] = dfHyperslab(ptr, dimAxes, info_k);
                val = readDatasetLL(fid, dsetPath, hs_start, hs_count);
                switch suffix
                    case 'df',    DF.df    = val;
                    case 'df_re', DF.df_re = val;
                    case 'df_im', DF.df_im = val;
                end

            elseif strcmp(suffix, 'args')
                DF.args = readDatasetLL(fid, dsetPath, [], []);

            elseif isStrDset
                DF.ax.(suffix) = string(readDatasetLL(fid, dsetPath, [], []));

            elseif any(strcmp(axisKeyWords, suffix))
                [ax_start, ax_count] = axHyperslab(ptr, suffix, info_k);
                DF.ax.(suffix) = readDatasetLL(fid, dsetPath, ax_start, ax_count);
            end
        end

    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);

    % Reconstruct complex df.
    if isfield(DF, 'df_re') && isfield(DF, 'df_im')
        DF.df = complex(DF.df_re, DF.df_im);
        DF    = rmfield(DF, {'df_re','df_im'});
    end

    if isfield(DF, 'df') && ~isfield(DF, 'ax')
        DF.ax = nexOp_generateAx(DF);
    end
end

% ── Low-level helpers ─────────────────────────────────────────────────────

function val = tryReadFlatDataset(fid, path)
% Returns non-empty if path is a dataset (not a group); empty otherwise.
    val = [];
    try
        did = H5D.open(fid, path);
        val = H5D.read(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
        H5D.close(did);
        if iscell(val), val = string(val); end
    catch
    end
end

function infos = buildDatasetInfos(fid, groupPath, names)
% Build struct array with .Name / .Dataspace.Size / .Datatype.Class for
% each link name — equivalent to h5info(...).Datasets.
    infos = repmat(struct('Name','','Dataspace',struct('Size',[]),'Datatype',struct('Class','')), ...
                   1, numel(names));
    for k = 1:numel(names)
        infos(k).Name = names{k};
        dpath = [groupPath '/' names{k}];
        try
            did = H5D.open(fid, dpath);
            fsid = H5D.get_space(did);
            [~, dims] = H5S.get_simple_extent_dims(fsid);
            H5S.close(fsid);
            tid = H5D.get_type(did);
            cls = H5T.get_class(tid);
            H5T.close(tid);
            H5D.close(did);
            infos(k).Dataspace.Size = dims;
            infos(k).Datatype.Class = cls;
        catch
        end
    end
end

function dimAxes = readDimOrderAtt(fid, dsetPath)
% Read the dim_order string attribute from a dataset. Returns {} on failure.
    dimAxes = {};
    try
        did = H5D.open(fid, dsetPath);
        aid = H5A.open(did, 'dim_order');
        raw = H5A.read(aid, 'H5ML_DEFAULT');
        H5A.close(aid);
        H5D.close(did);
        if iscell(raw), raw = raw{1}; end
        dimAxes = strtrim(strsplit(char(raw), ','));
    catch
        try, H5D.close(did); catch, end
    end
end

function val = readDatasetLL(fid, dsetPath, hs_start, hs_count)
% Read a dataset (full or hyperslab) using an already-open file ID.
% hs_start / hs_count are in h5info dimension order, 1-based (same as h5read).
    did  = H5D.open(fid, dsetPath);
    fsid = H5D.get_space(did);
    if ~isempty(hs_start) && ~isempty(hs_count)
        % Convert 1-based h5read convention to 0-based HDF5 C offset.
        H5S.select_hyperslab(fsid, 'H5S_SELECT_SET', ...
            double(hs_start - 1), [], double(hs_count), []);
        msid = H5S.create_simple(numel(hs_count), double(hs_count), double(hs_count));
        val  = H5D.read(did, 'H5ML_DEFAULT', msid, fsid, 'H5P_DEFAULT');
        H5S.close(msid);
    else
        val = H5D.read(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    end
    H5S.close(fsid);
    H5D.close(did);
end

% ── Hyperslab helpers ──────────────────────────────────────────────────────

function [start, count] = dfHyperslab(ptr, dimAxes, dsInfo)
% Build start/count for an ND df dataset.
% Returns [] when no axis range is constrained (caller does plain h5read).
%
% dim_order "f,t" → dimAxes = {'f','t'} → MATLAB dim 1 = f, dim 2 = t.
% Constraint loop uses MATLAB-order sizes (fliplr of Dataspace.Size) so
% dimAxes{d} aligns with dfSize_ml(d).  Output is fliplr'd back to
% h5info order before returning, since h5read uses Dataspace.Size order.
    start = []; count = [];
    if isempty(ptr) || isempty(dimAxes), return; end

    ndim      = numel(dimAxes);
    dfSize_ml = double(fliplr(dsInfo.Dataspace.Size));
    if numel(dfSize_ml) < ndim, dfSize_ml(end+1:ndim) = 1; end

    s = ones(1, ndim);
    c = dfSize_ml(1:ndim);
    anyConstrained = false;

    for d = 1:ndim
        axName = dimAxes{d};
        if isfield(ptr, axName)
            r = ptr.(axName).range;
            if numel(r) == 2 && r(2) >= r(1) && r(1) >= 1
                if r(1) > 1 || r(2) < dfSize_ml(d)
                    s(d)           = r(1);
                    c(d)           = r(2) - r(1) + 1;
                    anyConstrained = true;
                end
            end
        end
    end

    if anyConstrained
        dfSize_hdf5 = double(dsInfo.Dataspace.Size);
        start = fliplr(s);
        count = fliplr(c);
        if any(start + count - 1 > dfSize_hdf5(1:ndim))
            start = []; count = [];
        end
    end
end

function [start, count] = axHyperslab(ptr, axName, dsInfo)
% Build start/count for an axis array of any rank.
% Returns [] when the ptr range covers the full axis or no constraint exists.
%
% start/count are in the same dimension order as h5info's Dataspace.Size —
% do NOT fliplr. h5read uses that same order directly.
    start = []; count = [];
    if isempty(ptr) || ~isfield(ptr, axName), return; end
    r     = ptr.(axName).range;
    sz    = double(dsInfo.Dataspace.Size);
    axLen = prod(sz);
    if numel(r) ~= 2 || r(1) < 1 || r(2) > axLen
        return
    end
    if r(1) == 1 && r(2) == axLen
        return
    end
    ndim  = numel(sz);
    start = ones(1, ndim);
    count = sz;
    [~, axisDim] = max(sz);
    start(axisDim) = double(r(1));
    count(axisDim) = double(r(2) - r(1) + 1);
    if any(start + count - 1 > sz)
        error('axHyperslab: ptr.%s.range=[%d,%d] exceeds axis size=%d (sz=%s). start=%s count=%s', ...
            axName, r(1), r(2), axLen, mat2str(sz), mat2str(start), mat2str(count));
    end
end

function dimAxes = inferDimAxesFromInfo(dsets, axisKeyWords)
% Infer dim_order from numeric axis dataset lengths vs df dimensions.
% Matches each numeric axis (by total element count) to the unique df
% dimension with the same size.  Ambiguous or unmatched dimensions get ''.
% Returns {} when no axis can be placed.
    dimAxes = {};
    dfIdx = find(strcmp({dsets.Name}, 'df'), 1);
    if isempty(dfIdx)
        dfIdx = find(strcmp({dsets.Name}, 'df_re'), 1);
    end
    if isempty(dfIdx), return; end

    dfSize_ml = double(fliplr(dsets(dfIdx).Dataspace.Size));
    ndim      = numel(dfSize_ml);
    result    = repmat({''}, 1, ndim);
    assigned  = false(1, ndim);

    for k = 1:numel(dsets)
        axName = dsets(k).Name;
        if ~any(strcmp(axisKeyWords, axName)), continue; end
        if strcmp(dsets(k).Datatype.Class, 'H5T_STRING'), continue; end
        axLen = prod(double(dsets(k).Dataspace.Size));
        hits  = find(dfSize_ml == axLen & ~assigned);
        if numel(hits) == 1
            result{hits}   = axName;
            assigned(hits) = true;
        end
    end

    if any(assigned)
        last    = find(assigned, 1, 'last');
        dimAxes = result(1:last);
    end
end

function s = ptrToStruct(ptr)
% Convert nexObj_ptr (dynamicprops handle) to a plain struct.
    if isempty(ptr),   s = []; return; end
    if isstruct(ptr),  s = ptr; return; end
    if isa(ptr, 'nexObj_ptr')
        fns = properties(ptr);
        s   = struct;
        for i = 1:numel(fns)
            s.(fns{i}) = ptr.(fns{i});
        end
    else
        s = [];
    end
end
