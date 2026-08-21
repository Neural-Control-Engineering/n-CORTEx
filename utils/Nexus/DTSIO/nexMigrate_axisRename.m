function nexMigrate_axisRename(h5File, dfID, oldName, newName)
% nexMigrate_axisRename  Rename an axis dataset across all trial groups in an h5 file.
%
%   nexMigrate_axisRename(h5File, dfID, oldName, newName)
%
%   Example:
%     nexMigrate_axisRename('nexDTS_umap_rtPMTM_win250stride50.h5', ...
%                           'umap_rtPMTM_win250stride50', 'factor', 'latent')
%
%   Uses H5L.move — atomic rename, no data copied.

    fid = H5F.open(h5File, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
    nRenamed = 0;
    try
        % BFS over h5info struct (already in memory, no extra I/O)
        info  = h5info(h5File);
        stack = info.Groups(:);
        while ~isempty(stack)
            g     = stack(1);
            stack = [stack(2:end); g.Groups(:)];
            if ~endsWith(g.Name, ['/' dfID]), continue; end
            hasOld = any(strcmp({g.Datasets.Name}, oldName));
            if ~hasOld, continue; end
            gid = H5G.open(fid, g.Name);
            H5L.move(gid, oldName, gid, newName, 'H5P_DEFAULT', 'H5P_DEFAULT');
            H5G.close(gid);
            nRenamed = nRenamed + 1;
        end
    catch ME
        H5F.close(fid);
        rethrow(ME);
    end
    H5F.close(fid);
    fprintf('Renamed "%s" → "%s" in %d groups.\n', oldName, newName, nRenamed);
end
