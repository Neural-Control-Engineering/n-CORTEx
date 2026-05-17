function dtsIO_rechunkDTS(DTS, newH5File, chunkTargetBytes, batchSize, targetDFID)
% Copy all trial DF data from a disk-backed DTS into a new HDF5 file with
% automatic axis-aware chunking and dim_order attributes.
%
%   dtsIO_rechunkDTS(DTS, newH5File)
%   dtsIO_rechunkDTS(DTS, newH5File, chunkTargetBytes)              % default 128*1024
%   dtsIO_rechunkDTS(DTS, newH5File, chunkTargetBytes, batchSize)   % default 50
%   dtsIO_rechunkDTS(DTS, newH5File, chunkTargetBytes, batchSize, targetDFID)
%       targetDFID — rechunk only this dfID; all other groups are copied
%       verbatim (contiguous). Output file is still a complete replacement.
%       Pass '' or omit to rechunk all dfIDs.
%
% Parallel strategy:
%   Each batch of batchSize trials is read in parallel (parfor) — safe because
%   each worker opens its own read-only file handle with no shared state.
%   Writes are serial within each batch — HDF5 does not support concurrent
%   writes to the same file from multiple MATLAB workers.
%
%   Memory peak ≈ batchSize × (bytes per trial). At 10 MB/trial, 50 trials
%   ≈ 500 MB. Reduce batchSize if memory-constrained.
%
% Caller (Nexon.rechunkDTS) updates h5_path in the manifest after return.
% Original file is not deleted.

    if nargin < 3 || isempty(chunkTargetBytes), chunkTargetBytes = 128*1024; end
    if nargin < 4 || isempty(batchSize),         batchSize        = 50;       end
    if nargin < 5 || isempty(targetDFID),         targetDFID       = '';       end
    targetDFID = char(targetDFID);

    if ~ismember('h5_path', string(DTS.Properties.VariableNames))
        error('dtsIO_rechunkDTS:notDiskBacked', ...
              'DTS must be disk-backed (h5_path column required).');
    end

    newDir = fileparts(newH5File);
    if ~isempty(newDir) && ~isfolder(newDir), mkdir(newDir); end
    if isfile(newH5File), delete(newH5File); end

    nRows    = height(DTS);
    nBatches = ceil(nRows / batchSize);
    fprintf('Rechunking %d trials in %d batches → %s ...\n', nRows, nBatches, newH5File);

    for b = 1:nBatches
        bRows = (b-1)*batchSize+1 : min(b*batchSize, nRows);
        nB    = numel(bRows);

        % Slice per-trial inputs for parfor broadcast
        bSrcFiles = arrayfun(@(i) char(DTS.h5_path(i)), bRows, 'UniformOutput', false);
        bH5Roots  = arrayfun(@(i) char(DTS.h5_root(i)), bRows, 'UniformOutput', false);

        % ── Parallel read + rechunk preparation ──────────────────────────
        if isempty(gcp('nocreate')), parpool('local'); end
        batchData = cell(nB, 1);
        parfor j = 1:nB
            batchData{j} = readTrialForRechunk(bSrcFiles{j}, bH5Roots{j}, chunkTargetBytes, targetDFID);
        end

        % ── Serial write to single output file ───────────────────────────
        for j = 1:nB
            if ~isempty(batchData{j})
                writeTrialRechunked(newH5File, bH5Roots{j}, batchData{j});
            end
        end

        fprintf('  batch %d / %d  (trials %d–%d)\n', b, nBatches, bRows(1), bRows(end));
    end

    fprintf('Rechunk complete → %s\n', newH5File);
end

% ── Parallel read worker (one trial) ──────────────────────────────────────

function td = readTrialForRechunk(srcFile, h5Root, chunkTargetBytes, targetDFID)
% Returns a trial-data struct ready for serial write. All compute (chunk
% spec, dim_order) happens here so the write phase is purely I/O.
    td = [];
    try
        info = h5info(srcFile, h5Root);
    catch
        return;
    end

    td.h5Root  = h5Root;
    td.groups  = {};   % cell of group structs  {dfid, df, ax, args, chunkSz, dimOrder}
    td.scalars = {};   % cell of scalar structs  {path, val, isString}

    % ── DF groups ─────────────────────────────────────────────────────────
    for g = 1:numel(info.Groups)
        dfid      = h5LeafName(info.Groups(g).Name);
        doRechunk = isempty(targetDFID) || strcmp(dfid, targetDFID);
        grp       = readDFGroup(srcFile, h5Root, dfid, chunkTargetBytes, doRechunk);
        if ~isempty(grp)
            td.groups{end+1} = grp;
        end
    end

    % ── Scalar datasets at trial root ─────────────────────────────────────
    for d = 1:numel(info.Datasets)
        name = info.Datasets(d).Name;
        try
            val = h5read(srcFile, [h5Root '/' name]);
            td.scalars{end+1} = struct( ...
                'path',     [h5Root '/' name], ...
                'val',      val, ...
                'isString', strcmp(info.Datasets(d).Datatype.Class, 'H5T_STRING'));
        catch, end
    end
end

function grp = readDFGroup(srcFile, h5Root, dfid, chunkTargetBytes, doRechunk)
% Read one dfID group from srcFile, infer chunk spec, return prepared struct.
    grp       = [];
    groupPath = [h5Root '/' dfid];
    try
        info = h5info(srcFile, groupPath);
    catch
        return;
    end

    % Read all datasets
    raw = struct;
    for k = 1:numel(info.Datasets)
        name = info.Datasets(k).Name;
        try, raw.(matlab.lang.makeValidName(name)) = h5read(srcFile, [groupPath '/' name]); catch, end
    end

    % Reconstruct DF
    DF = rawToDF(raw);
    if isempty(fieldnames(DF)), return; end

    % Infer axis→dim mapping and compute chunk spec (skip for verbatim copy)
    if doRechunk
        DF = inferPtr(DF);
        [chunkSz, dimOrder] = dfChunkSpecDirect(DF, chunkTargetBytes);
    else
        chunkSz  = [];
        dimOrder = '';
    end

    grp.dfid     = dfid;
    grp.df       = DF.df;
    grp.chunkSz  = chunkSz;
    grp.dimOrder = dimOrder;
    if isfield(DF,'ax'),   grp.ax   = DF.ax;   else, grp.ax   = struct; end
    if isfield(DF,'args'), grp.args = DF.args;  else, grp.args = [];     end
end

% ── Serial write (one trial) ───────────────────────────────────────────────

function writeTrialRechunked(dstFile, h5Root, td)
    axisKeyWords = ["f","t","chans","factor","dropout","latent"];

    % ── DF groups ─────────────────────────────────────────────────────────
    for g = 1:numel(td.groups)
        grp  = td.groups{g};
        base = [h5Root '/' grp.dfid];

        if ~isreal(grp.df)
            dre = [base '/df_re']; dim_p = [base '/df_im'];
            h5writeSafeChunk(dstFile, dre,   double(real(grp.df)), grp.chunkSz);
            h5writeSafeChunk(dstFile, dim_p, double(imag(grp.df)), grp.chunkSz);
            if ~isempty(grp.dimOrder)
                try, h5writeatt(dstFile, dre,   'dim_order', grp.dimOrder); catch, end
                try, h5writeatt(dstFile, dim_p, 'dim_order', grp.dimOrder); catch, end
            end
        else
            dset = [base '/df'];
            h5writeSafeChunk(dstFile, dset, double(grp.df), grp.chunkSz);
            if ~isempty(grp.dimOrder)
                try, h5writeatt(dstFile, dset, 'dim_order', grp.dimOrder); catch, end
            end
        end

        axFields = fieldnames(grp.ax);
        for k = 1:numel(axFields)
            suf = axFields{k};
            val = grp.ax.(suf);
            if isempty(val), continue; end
            if isnumeric(val) && any(strcmp(axisKeyWords, suf))
                h5writeSafeChunk(dstFile, [base '/' suf], double(val), []);
            elseif isstring(val) || iscellstr(val)
                c = cellstr(val);
                try, h5create(dstFile,[base '/' suf],size(c),'Datatype','string'); catch, end
                h5write(dstFile, [base '/' suf], c);
            end
        end

        if ~isempty(grp.args)
            h5writeSafeChunk(dstFile, [base '/args'], double(grp.args), []);
        end
    end

    % ── Scalars ───────────────────────────────────────────────────────────
    for s = 1:numel(td.scalars)
        sc = td.scalars{s};
        if sc.isString
            c = cellstr(string(sc.val));
            try, h5create(dstFile, sc.path, size(c), 'Datatype','string'); catch, end
            try, h5write(dstFile, sc.path, c); catch, end
        else
            arr = double(sc.val);
            try, h5create(dstFile, sc.path, size(arr), 'Datatype','double'); catch, end
            try, h5write(dstFile, sc.path, arr); catch, end
        end
    end
end

% ── Shared helpers ─────────────────────────────────────────────────────────

function DF = rawToDF(raw)
    DF = struct;
    if isfield(raw,'df')
        DF.df = raw.df;
    elseif isfield(raw,'df_re') && isfield(raw,'df_im')
        DF.df = complex(raw.df_re, raw.df_im);
    end
    if ~isfield(DF,'df') || isempty(DF.df), DF = struct; return; end
    axKeywords = {'f','t','chans','factor','dropout','latent'};
    for k = 1:numel(axKeywords)
        kk = axKeywords{k};
        if isfield(raw, kk), DF.ax.(kk) = raw.(kk); end
    end
    if isfield(raw,'args'), DF.args = raw.args; end
end

function DF = inferPtr(DF)
% Infer axis→dimension mapping from df shape and axis array lengths.
% Plain struct output (no nexObj_ptr wrapping needed for chunk computation).
    if ~isfield(DF,'df') || ~isfield(DF,'ax'), return; end
    dfSz = size(DF.df); dimsTaken = [];
    axFields = fieldnames(DF.ax);
    for i = 1:numel(axFields)
        ax    = axFields{i};
        axLen = numel(DF.ax.(ax));
        dims  = find(dfSz == axLen);
        dims  = dims(~ismember(dims, dimsTaken));
        if isempty(dims), continue; end
        DF.ptr.(ax).dim   = dims(1);
        DF.ptr.(ax).range = [1, axLen];
        dimsTaken = [dimsTaken, dims(1)];
    end
end

function [chunkSz, dimOrder] = dfChunkSpecDirect(DF, chunkTargetBytes)
    chunkSz = []; dimOrder = '';
    if ~isfield(DF,'df') || isempty(DF.df), return; end
    if ~isfield(DF,'ptr') || isempty(DF.ptr), return; end
    dfSz = size(DF.df); ndim = numel(dfSz);
    cSz = dfSz; axNames = repmat({''}, 1, ndim);
    pFields = fieldnames(DF.ptr);
    axDims = []; axSizes = [];
    for i = 1:numel(pFields)
        ax = pFields{i}; dim = DF.ptr.(ax).dim;
        if ~isscalar(dim) || dim < 1 || dim > ndim, continue; end
        axDims(end+1) = dim; axSizes(end+1) = dfSz(dim); %#ok<AGROW>
        axNames{dim} = ax;
    end
    if ~isempty(axDims)
        targetElems = chunkTargetBytes / 8;
        [~, sortIdx] = sort(axSizes,'ascend');
        budget = targetElems; chunkVals = zeros(size(axDims));
        for k = 1:numel(sortIdx)
            remaining = numel(sortIdx) - k + 1;
            ci = min(axSizes(sortIdx(k)), max(1, floor(budget^(1/remaining))));
            chunkVals(sortIdx(k)) = ci; budget = budget / ci;
        end
        for i = 1:numel(axDims), cSz(axDims(i)) = chunkVals(i); end
    end
    chunkSz = cSz;
    if all(~cellfun('isempty', axNames)), dimOrder = strjoin(axNames, ','); end
end

function h5writeSafeChunk(h5File, dset, arr, chunkSz)
    if nargin < 4, chunkSz = []; end
    useChunk = ~isempty(chunkSz) && numel(chunkSz)==ndims(arr) && ...
               all(chunkSz>=1) && all(chunkSz<=size(arr));
    if useChunk
        createArgs = {'Datatype','double','ChunkSize',chunkSz};
    else
        createArgs = {'Datatype','double'};
    end
    try
        h5create(h5File, dset, size(arr), createArgs{:});
    catch ME
        if ~contains(ME.message,'already exists'), rethrow(ME); end
        fid = H5F.open(h5File,'H5F_ACC_RDWR','H5P_DEFAULT');
        try, H5L.delete(fid,dset,'H5P_DEFAULT'); finally, H5F.close(fid); end
        h5create(h5File, dset, size(arr), createArgs{:});
    end
    h5write(h5File, dset, arr);
end

function name = h5LeafName(fullPath)
    idx  = find(fullPath == '/', 1, 'last');
    name = fullPath(idx+1:end);
end
