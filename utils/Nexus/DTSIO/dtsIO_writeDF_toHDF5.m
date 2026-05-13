function dtsIO_writeDF_toHDF5(h5File, h5Root, DFID, DF)
% Write one DF struct into an HDF5 file under h5Root/DFID/.
% Writes df array, axis arrays, and args.
% Shared by dtsIO_writeHDF5 and nexus_exportDTS.

    axisKeyWords = ["f","t","chans","factor","dropout","latent"];

    if isfield(DF, 'df') && ~isempty(DF.df)
        if ~isreal(DF.df)
            % Complex df — store real and imaginary parts as sibling datasets.
            % Reconstruct with complex(df_re, df_im) on read.
            h5writeSafe(h5File, [h5Root '/' DFID '/df_re'], double(real(DF.df)));
            h5writeSafe(h5File, [h5Root '/' DFID '/df_im'], double(imag(DF.df)));
        else
            h5writeSafe(h5File, [h5Root '/' DFID '/df'], double(DF.df));
        end
    end

    if isfield(DF, 'ax')
        axFields = fieldnames(DF.ax);
        for k = 1:numel(axFields)
            suf = axFields{k};
            val = DF.ax.(suf);
            if isempty(val), continue; end
            if isnumeric(val) && any(strcmp(axisKeyWords, suf))
                h5writeSafe(h5File, [h5Root '/' DFID '/' suf], double(val));
            elseif isstring(val) || iscellstr(val)
                % String axes bypass axisKeyWords — they are always intentional.
                h5writeStringSafe(h5File, [h5Root '/' DFID '/' suf], val);
            end
        end
    end

    if isfield(DF, 'args') && isnumeric(DF.args) && ~isempty(DF.args)
        h5writeSafe(h5File, [h5Root '/' DFID '/args'], double(DF.args));
    end
end

% ── Helpers ───────────────────────────────────────────────────────────────

function h5writeSafe(h5File, dset, arr)
    try
        h5create(h5File, dset, size(arr), 'Datatype', 'double');
    catch ME
        if ~contains(ME.message, 'already exists')
            rethrow(ME);
        end
        % Dataset exists — delete and recreate so that overwriting with a
        % different shape never errors. HDF5 fixed-size datasets cannot be
        % resized in place; delete+recreate is the only portable solution.
        % try/finally guarantees H5F.close even if H5L.delete throws,
        % preventing a write-lock leak that would block subsequent h5write calls.
        fid = H5F.open(h5File, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
        try
            H5L.delete(fid, dset, 'H5P_DEFAULT');
        finally
            H5F.close(fid);
        end
        h5create(h5File, dset, size(arr), 'Datatype', 'double');
    end
    h5write(h5File, dset, arr);
end

function h5writeStringSafe(h5File, dset, val)
    c = cellstr(val);   % normalise string/cellstr → cell of chars
    try
        h5create(h5File, dset, size(c), 'Datatype', 'string');
    catch ME
        if ~contains(ME.message, 'already exists')
            rethrow(ME);
        end
    end
    h5write(h5File, dset, c);
end
