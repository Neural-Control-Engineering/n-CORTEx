function h5Root = nex_buildH5Root(sessionLabel, trialNumber)
% Build the HDF5 group path for one trial.
% Shared by nexus_exportDTS, dtsIO_writeHDF5, and the sink path so the
% per-trial address is never computed in more than one place.
%
%   sessionLabel : string  e.g. "subj01--2024-03-15--baseline"
%   trialNumber  : scalar  e.g. 7
%
%   h5Root       : string  e.g. "/subj01/2024-03-15/baseline/trial_0007"

    parts  = strsplit(string(sessionLabel), "--");
    parts  = strtrim(parts(strlength(parts) > 0));
    h5Root = "/" + strjoin([parts(:)', {sprintf("trial_%04d", trialNumber)}], "/");
end
