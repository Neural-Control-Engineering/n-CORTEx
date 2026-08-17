function nexLaunch_extractPanel(parent, nexon)
% nexLaunch_extractPanel  Embed a nexTract runner into `parent` (uipanel/figure).
%
%   nexLaunch_extractPanel(parent, nexon)
%
% Pick a DF source and an extraction function, optionally name the output and
% toggle skip-existing, hit Extract → runs
%   nexTract(nexon, str2func(fcn), <source>, [], fcn, <dfColName|[]>, opts)
% i.e. the same call you'd type by hand. The function box is an editable
% dropdown seeded with a curated list — pick one or type any function name.
% New outputs (e.g. lfp_<fcn>) become selectable after the run / Refresh.

    C = nexon.settings.Colors; GREEN = C.cyberGreen; BLACK = [0 0 0];

    uilabel(parent, "Text", "source", "Position", [5,235,160,18], "FontColor", GREEN);
    srcDD = uidropdown(parent, "Position", [5,213,160,22], ...
        "Items", nexLaunch_listSources(nexon, []));

    uilabel(parent, "Text", "function", "Position", [5,189,160,16], "FontColor", GREEN);
    fcnDD = uidropdown(parent, "Position", [5,167,160,22], ...
        "Editable", "on", "Items", seedFcns(), "Value", "");

    uilabel(parent, "Text", "output name (opt)", "Position", [5,143,160,16], "FontColor", GREEN);
    colField = uieditfield(parent, "text", "Position", [5,121,160,22], ...
        "Placeholder", "<source>_<function>");

    skipChk = uicheckbox(parent, "Text", "skip existing", "Position", [5,98,160,20], ...
        "FontColor", GREEN, "Value", true);
    trialChk = uicheckbox(parent, "Text", "current trial only", "Position", [5,77,160,20], ...
        "FontColor", GREEN, "Value", false);

    extractBtn = uibutton(parent, "Text", "Extract", "Position", [5,49,160,24], ...
        "BackgroundColor", GREEN, "FontColor", BLACK, "ButtonPushedFcn", @(~,~)onExtract());
    uibutton(parent, "Text", "Refresh sources", "Position", [5,26,160,20], ...
        "BackgroundColor", BLACK, "FontColor", GREEN, "ButtonPushedFcn", @(~,~)onRefresh());

    status = uilabel(parent, "Text", "", "Position", [5,4,170,20], ...
        "FontColor", GREEN, "WordWrap", "on");

    function onExtract()
        dfID = string(srcDD.Value);
        if dfID == "" || dfID == "(no sources)", status.Text = "no source"; return; end
        fcnName = strtrim(string(fcnDD.Value));
        if fcnName == "", status.Text = "pick a function"; return; end
        if isempty(which(char(fcnName)))
            status.Text = "unknown function: " + fcnName; return;
        end
        % Empty output box → [] so nexTract uses its default <dfID>_<fcnName>.
        colName   = strtrim(string(colField.Value));
        dfColName = [];
        if colName ~= "", dfColName = colName; end
        opts = struct("skipExisting", logical(skipChk.Value));

        % "current trial only" → restrict nexTract to the routed row(s). Empty
        % mask = all rows (nexTract's default). If the router resolves nothing,
        % abort rather than silently falling through to a full-column extract.
        mask = [];
        scope = "all rows";
        if trialChk.Value
            mask = nex_getRouterIdx(nexon);
            if ~any(mask), status.Text = "router matches no trial"; return; end
            scope = sprintf("trial row %s", mat2str(find(mask(:)).'));
        end

        extractBtn.Enable = "off";
        status.Text = "running " + fcnName + " (" + scope + ") ...";
        drawnow;
        try
            nexTract(nexon, str2func(char(fcnName)), dfID, mask, char(fcnName), dfColName, opts);
            status.Text = "done: " + fcnName + " <- " + dfID;
            srcDD.Items = nexLaunch_listSources(nexon, []);   % new output selectable
        catch e
            disp(getReport(e, "extended", "hyperlinks", "on"));
            status.Text = e.message;
        end
        extractBtn.Enable = "on";
    end

    function onRefresh()
        srcDD.Items = nexLaunch_listSources(nexon, []);
    end
end

function items = seedFcns()
% Curated starting set for the editable function dropdown. Editable=on, so any
% function name can be typed; extend this list as common ops stabilise.
    items = {'nex_pcaNoiseRm', 'rtPMTM_magnitude_roll'};
end
