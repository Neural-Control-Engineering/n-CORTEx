function nexLaunch_panel(parent, nexon, dfIDFilter)
% nexLaunch_panel  Embed a figure launcher into `parent` (uifigure or uipanel).
%
%   nexLaunch_panel(parent, nexon)              % all DF sources
%   nexLaunch_panel(parent, nexon, dfIDFilter)  % restrict source list
%
% Pick a DF source and a figure type, hit Launch → builds (or reuses) that
% source's categorical hub (nexLaunch_getCategorical) and constructs the chosen
% figure on it (nexLaunch_registry). Stateless: the only retained state is the
% per-dfID categorical cache on the nexon.
%
%   dfIDFilter : optional string array of name prefixes to include, trailing
%                '*' allowed (e.g. ["lfp","RTS_spk_*"]). [] = all sources.

    if nargin < 3, dfIDFilter = []; end
    C = nexon.settings.Colors; GREEN = C.cyberGreen; BLACK = [0 0 0];

    uilabel(parent, "Text", "source", "Position", [5,235,160,20], "FontColor", GREEN);
    srcDD = uidropdown(parent, "Position", [5,213,160,22], ...
        "Items", listSources(nexon, dfIDFilter));

    uilabel(parent, "Text", "figure", "Position", [5,185,160,20], "FontColor", GREEN);
    typeDD = uidropdown(parent, "Position", [5,163,160,22], ...
        "Items", string(fieldnames(nexLaunch_registry()))');

    uibutton(parent, "Text", "Launch", "Position", [5,128,160,28], ...
        "BackgroundColor", GREEN, "FontColor", BLACK, "ButtonPushedFcn", @(~,~)onLaunch());
    uibutton(parent, "Text", "Refresh sources", "Position", [5,100,160,22], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, "ButtonPushedFcn", @(~,~)onRefresh());

    status = uilabel(parent, "Text", "", "Position", [5,66,165,28], ...
        "FontColor", GREEN, "WordWrap", "on");

    function onLaunch()
        dfID = string(srcDD.Value);
        if dfID == "" || dfID == "(no sources)", return; end
        try
            ctg = nexLaunch_getCategorical(nexon, dfID);
            reg = nexLaunch_registry();
            reg.(typeDD.Value)(ctg);
            status.Text = sprintf("%s <- %s", typeDD.Value, dfID);
        catch e
            status.Text = e.message;
        end
    end

    function onRefresh()
        srcDD.Items = listSources(nexon, dfIDFilter);
    end
end

function items = listSources(nexon, filt)
% Enumerate DF sources in the DTS, dropping address/meta columns and applying
% the optional prefix filter.
    items = "(no sources)";
    try
        ids = dtsIO_readDFIDs(nexon.console.BASE.DTS);
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
