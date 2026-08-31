function nexAtlas_h5overwrite(h5file, dsetPath, data)
% Delete an HDF5 dataset if it exists, then recreate and write.
% Needed for growing datasets (unit catalog) where size changes each session.
% Note: deleted space is not reclaimed from the file — run h5repack periodically
% if fragmentation becomes a concern (typically won't for catalog sizes <1000 units).

    % Delete existing dataset (low-level API — h5write cannot resize)
    try
        fid = H5F.open(h5file, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
        H5L.delete(fid, dsetPath, 'H5P_DEFAULT');
        H5F.close(fid);
    catch
        try, H5F.close(fid); catch, end
    end

    % Create and write
    if isnumeric(data)
        h5create(h5file, dsetPath, size(data), 'Datatype', class(data));
        h5write(h5file, dsetPath, data);
    elseif isstring(data) || iscellstr(data)
        data = cellstr(string(data(:)));
        h5create(h5file, dsetPath, size(data), 'Datatype', 'string');
        h5write(h5file, dsetPath, data);
    end
end
