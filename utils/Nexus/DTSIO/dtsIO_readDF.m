function DF = dtsIO_readDF(nexon, DFID, dtsIdx, ptr)
% General-purpose dataframe reader from the Nexus datastore.
%
%   DF = dtsIO_readDF(nexon, DFID, dtsIdx)
%   DF = dtsIO_readDF(nexon, DFID, dtsIdx, ptr)
%
%   ptr : optional nexObj_ptr or plain struct with .(axName).range = [i1, i2].
%         When the target dataset has a dim_order attribute (written by chunked
%         dtsIO_writeDF_toHDF5), only the hyperslab defined by ptr ranges is
%         loaded from disk. Falls back to full read for legacy data.

    if nargin < 4, ptr = []; end

    dtsCols = nexon.console.BASE.DTS.Properties.VariableNames;
    if ~ismember(DFID, dtsCols)
        if isempty(dtsIdx)
            % Empty index uses nexon for router-based row selection; override
            % cannot be injected here without restructuring readHDF5.
            DF = dtsIO_readHDF5(nexon, char(DFID), dtsIdx, ptr);
        else
            % Route to the dfID-specific file if one has been registered by
            % nexTract (via dtsIO_patchManifest), otherwise fall back to h5_path.
            DTS_route    = nexon.console.BASE.DTS;
            overrideCol  = "h5_path_" + string(DFID);
            if ismember(overrideCol, DTS_route.Properties.VariableNames)
                DTS_route.h5_path = DTS_route.(char(overrideCol));
            end
            DF = dtsIO_readHDF5(DTS_route, char(DFID), dtsIdx, ptr);
        end
    else
        if isscalar(dtsIdx)
            DF = dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx, ptr);
        elseif isempty(dtsIdx)
            dtsIdx = nex_getRouterIdx(nexon);
            DF = dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx, ptr);
        else
            DF = {};
            for i = 1:length(dtsIdx)
                DF = [DF; dtsIO_composeDF(nexon.console.BASE.DTS, DFID, dtsIdx(i), ptr)]; %#ok<AGROW>
            end
        end
    end
end
