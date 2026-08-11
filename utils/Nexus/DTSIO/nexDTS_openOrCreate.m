function [h5File, manifest] = nexDTS_openOrCreate(dtsPath)
% Resolve the nexDTS HDF5 path and load any existing manifest.
% Creates dtsPath on disk if it does not exist yet.
%
%   h5File   : fullfile(dtsPath, 'nexDTS.h5')  (may not exist yet)
%   manifest : existing manifest table, or [] on first use

    if ~isfolder(dtsPath)
        mkdir(dtsPath);
    end
    h5File       = fullfile(dtsPath, 'nexDTS.h5');
    manifestFile = fullfile(dtsPath, 'nexDTS_manifest.mat');
    if isfile(manifestFile)
        S = load(manifestFile);
        % Writers are inconsistent about the variable name (manifest / DTS /
        % DTS_manifest) — accept whichever is present.
        if isfield(S, 'manifest')
            manifest = S.manifest;
        elseif isfield(S, 'DTS_manifest')
            manifest = S.DTS_manifest;
        elseif isfield(S, 'DTS')
            manifest = S.DTS;
        else
            manifest = [];
        end
    else
        manifest = [];
    end
end
