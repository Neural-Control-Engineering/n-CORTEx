function ids = nexOp_listResults(nexObj_or_dir)
% List resultIDs saved in nexRESULTS.h5 alongside the DTS.
%
%   ids = nexOp_listResults(nexObj)
%   ids = nexOp_listResults('/path/to/dts/dir')
%
% Returns a string array of resultIDs (empty if file not found).

    if ischar(nexObj_or_dir) || isstring(nexObj_or_dir)
        h5Dir = char(nexObj_or_dir);
    else
        nexon = nexObj_or_dir.nexon;
        h5Dir = fileparts(char(nexon.console.BASE.DTS.h5_path(1)));
    end

    h5File = fullfile(h5Dir, 'nexRESULTS.h5');
    ids    = string.empty(0, 1);
    if ~isfile(h5File), return; end

    try
        info = h5info(h5File, '/');
        if ~isempty(info.Groups)
            ids = string({info.Groups.Name})';
            ids = extractAfter(ids, '/');
        end
    catch, end
end
