function items = nexLaunch_listSources(nexon, filt)
% Enumerate DF sources in the DTS for a launcher dropdown, dropping address/meta
% columns and applying an optional prefix filter. Shared by nexLaunch_panel
% (INSPECT) and nexLaunch_extractPanel (EXTRACT).
%
%   filt : optional string array of name prefixes to include, trailing '*'
%          allowed (e.g. ["lfp","RTS_spk_*"]). [] = all sources.
%
% Returns a cellstr for direct assignment to a uidropdown's Items, or the single
% "(no sources)" placeholder when nothing matches.

    if nargin < 2, filt = []; end
    items = "(no sources)";
    try
        ids = dtsIO_listDFIDs(nexon.console.BASE.DTS);
    catch
        return;
    end
    ids  = ids(:).';
    meta = ["h5_path","h5_root","sessionLabel","trialNumber","Time"];
    ids  = ids(~ismember(ids, meta));
    if ~isempty(filt)
        pref = erase(string(filt), "*");
        keep = arrayfun(@(id) any(startsWith(id, pref)), ids);
        ids  = ids(keep);
    end
    if isempty(ids), return; end
    items = cellstr(ids);
end
