function DF = dtsIO_readHDF5(DTS, DFID, dtsIdx)
% Read a DF struct from HDF5 for one or more manifest rows.
% Internal helper called by dtsIO_composeDF when DTS is disk-backed.
%
%   dtsIdx : scalar integer, logical vector, or numeric vector of row indices

    axisKeyWords = ["f","t","chans","factor","dropout","latent"];

    if islogical(dtsIdx)
        rows = find(dtsIdx);
    else
        rows = dtsIdx(:)';
    end

    if isscalar(rows)
        h5File = char(DTS.h5_path(rows));
        h5Root = char(DTS.h5_root(rows));
        DF = readOneTrialHDF5(h5File, h5Root, DFID, axisKeyWords);
    else
        DF = {};
        for i = 1:numel(rows)
            h5File = char(DTS.h5_path(rows(i)));
            h5Root = char(DTS.h5_root(rows(i)));
            DF = [DF; {readOneTrialHDF5(h5File, h5Root, DFID, axisKeyWords)}];
        end
    end
end

% ---------------------------------------------------------------------------
function DF = readOneTrialHDF5(h5File, h5Root, DFID, axisKeyWords)
    DF = struct;
    groupPath = [h5Root '/' DFID];

    try
        info = h5info(h5File, groupPath);
    catch
        return; % dfID absent for this trial
    end

    for k = 1:numel(info.Datasets)
        suffix = info.Datasets(k).Name;
        arr    = h5read(h5File, [groupPath '/' suffix]);
        if strcmp(suffix, 'df')
            DF.df = arr;
        elseif any(strcmp(axisKeyWords, suffix))
            DF.ax.(suffix) = arr;
        elseif strcmp(suffix, 'args')
            DF.args = arr;
        end
    end

    if isfield(DF, 'df') && ~isfield(DF, 'ax')
        DF.ax = nexOp_generateAx(DF);
    end
end
