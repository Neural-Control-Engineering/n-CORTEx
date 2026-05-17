function nexTract(nexon, fcn, dfID, mask, fcnName)

    if nargin < 5
        fcnName = func2str(fcn);
    end

    rowStart = 1;

    dtsRows    = height(nexon.console.BASE.DTS);
    dfID_entry = strrep(dfID, "_df", "");
    dfColName  = sprintf("%s_%s", dfID_entry, fcnName);

    isDiskBacked = ismember('h5_path', nexon.console.BASE.DTS.Properties.VariableNames);

    % Each nexTract run writes to its own dfColumn-specific HDF5 file.
    % This avoids flock(LOCK_EX) conflicts with concurrent RDONLY sessions on
    % the shared source file — no locking workarounds needed.
    if isDiskBacked
        h5FileIn  = char(nexon.console.BASE.DTS.h5_path(1));
        [d, b, e] = fileparts(h5FileIn);
        h5FileOut = fullfile(d, [b '_' char(dfColName) e]);
    end

    % minLength — read lengths from the INPUT file (source dfID)
    if isDiskBacked
        lengths  = zeros(1, dtsRows);
        fapl_len = H5P.create('H5P_FILE_ACCESS');
        H5P.set_fclose_degree(fapl_len, 'H5F_CLOSE_STRONG');
        fid_len = H5F.open(h5FileIn, 'H5F_ACC_RDONLY', fapl_len);
        H5P.close(fapl_len);
        for ii = 1:dtsRows
            dset_path = char(nexon.console.BASE.DTS.h5_root(ii) + "/" + dfID_entry + "/df");
            try
                if H5L.exists(fid_len, dset_path, 'H5P_DEFAULT')
                    did_l = H5D.open(fid_len, dset_path);
                    sid_l = H5D.get_space(did_l);
                    [~, sz_l] = H5S.get_simple_extent_dims(sid_l);
                    lengths(ii) = sz_l(1);
                    H5S.close(sid_l);
                    H5D.close(did_l);
                end
            catch
            end
        end
        H5F.close(fid_len);
        minLength = min(lengths(lengths > 0));
    else
        minLength = arrayfun(@(x) size(x{1},2), nexon.console.BASE.DTS.(dfID), "UniformOutput", true);
        minLength(minLength == 0) = [];
        minLength = min(minLength);
    end

    DFOUT = {}; %#ok<NASGU>
    for i = rowStart:dtsRows
        disp(i);

        % Skip rows already written to the OUTPUT file.
        if isDiskBacked && exist(h5FileOut, 'file')
            grp    = char(nexon.console.BASE.DTS.h5_root(i) + "/" + dfColName);
            fapl_sk = H5P.create('H5P_FILE_ACCESS');
            H5P.set_fclose_degree(fapl_sk, 'H5F_CLOSE_STRONG');
            fid_sk = H5F.open(h5FileOut, 'H5F_ACC_RDONLY', fapl_sk);
            H5P.close(fapl_sk);
            done = false;
            try
                done = H5L.exists(fid_sk, [grp '/df'],    'H5P_DEFAULT') || ...
                       H5L.exists(fid_sk, [grp '/df_im'], 'H5P_DEFAULT');
            catch
            end
            H5F.close(fid_sk);
            if done, continue; end
        end

        DF_in = dtsIO_readDF(nexon, dfID_entry, i);
        try
            df = DF_in.df;
        catch
            continue
        end
        if ~isempty(df)
            try
                if size(df, 2) > minLength * 1.01
                    ptr = nexInit_axisPointer(DF_in.df, DF_in.ax);
                    DF_in.df = df(:, 1:minLength);
                    axFields = convertCharsToStrings(fieldnames(DF_in.ax));
                    axDims = [];
                    for j = 1:length(axFields); axDims = [axDims; ptr.(axFields(j)).dim]; end %#ok<AGROW>
                    axSel = axFields(axDims == 2);
                    try
                        ax = DF_in.ax.(axSel);
                    catch
                        try
                            ax = DF_in.ax.t;  axSel = "t";
                        catch e
                            disp(getReport(e));
                        end
                    end
                    DF_in.ax.(axSel) = ax(1:minLength);
                end
                args         = extractMethodCfg(fcnName);
                args.idx_row = i;
                DF_out       = fcn(DF_in, args);
            catch e
                disp(getReport(e));
                continue
            end
        else
            continue
        end

        try
            if isDiskBacked
                h5Root = char(nexon.console.BASE.DTS.h5_root(i));
                dtsIO_writeDF_toHDF5(h5FileOut, h5Root, char(dfColName), DF_out);
            else
                dtsIO_writeDF(nexon, DF_out, dfColName, i);
            end
        catch e
            warning("nexTract: write failed for row %d — %s\nAborting.", i, e.message);
            break
        end
    end

    % Register the output file in the manifest so reads route correctly.
    if isDiskBacked && exist(h5FileOut, 'file')
        dtsIO_patchManifest(nexon, dfColName, h5FileOut);
    end
end