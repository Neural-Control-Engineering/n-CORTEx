function ok = sessionArchivesComplete(localSessionPath, cloudSessionPath)
% True if local archives are present and plausibly complete relative to cloud.
% Compares .7z and .zip archives at root + one level deep (imec subfolders).
%
% When both sides use the same format (7z vs 7z, zip vs zip) a 20% size
% tolerance is applied. When formats differ (7z vs zip or vice versa) the
% size comparison is skipped — 7z/LZMA2 is legitimately 1-2 GB smaller than
% zip/deflate for the same raw data, so a ratio check would always misfire.
% In that case we only verify that local archives are present and non-empty.
%
% Usage (inline debug):
%   localPath = fullfile(params.paths.Data.RAW.NPXLS.local, exp_template);
%   cloudPath = fullfile(params.paths.Data.RAW.NPXLS.cloud, exp_template);
%   sessionArchivesComplete(localPath, cloudPath)
    dLocal7z  = [dir(fullfile(localSessionPath,  '*.7z'));  dir(fullfile(localSessionPath,  '*', '*.7z'))];
    dLocalZip = [dir(fullfile(localSessionPath,  '*.zip')); dir(fullfile(localSessionPath,  '*', '*.zip'))];
    dCloud7z  = [dir(fullfile(cloudSessionPath, '*.7z'));  dir(fullfile(cloudSessionPath, '*', '*.7z'))];
    dCloudZip = [dir(fullfile(cloudSessionPath, '*.zip')); dir(fullfile(cloudSessionPath, '*', '*.zip'))];

    dLocal = [dLocal7z; dLocalZip];
    dCloud = [dCloud7z; dCloudZip];

    if isempty(dLocal)
        ok = false;
        return;
    end

    localBytes = sum([dLocal.bytes]);
    if localBytes == 0
        ok = false;
        return;
    end

    % If cloud has nothing to compare against, trust local.
    if isempty(dCloud)
        ok = true;
        return;
    end

    % Same-format comparison: apply size tolerance.
    % Mixed-format (7z local vs zip cloud or vice versa): skip size check.
    localIs7z  = ~isempty(dLocal7z)  && isempty(dLocalZip);
    cloudIs7z  = ~isempty(dCloud7z)  && isempty(dCloudZip);
    sameFormat = (localIs7z == cloudIs7z);

    if sameFormat
        cloudBytes = sum([dCloud.bytes]);
        ok = cloudBytes > 0 && (abs(localBytes - cloudBytes) / cloudBytes) < 0.20;
    else
        ok = true;   % cross-format: local non-empty is sufficient
    end
end
