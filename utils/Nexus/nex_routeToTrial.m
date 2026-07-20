function nex_routeToTrial(nexon, sessionLabel, trialNumber)
% nex_routeToTrial  Point the BASE router at (sessionLabel, trialNumber) and
% refresh the whole nexon.
%
%   nex_routeToTrial(nexon, sessionLabel, trialNumber)
%
% Sets the router's session coordinates (subj/date/phase[/site], parsed from
% sessionLabel) and its trial field, then fires the router's own callback
% (routerEntryChanged) so the ENTIRE nexon repopulates for that trial in one
% pass — the NPXLS timecourse/spectrogram scopes, the SLRT signal scope, and
% every nexLaunch'd scene figure — exactly as a manual router change would.
%
% Routing the full session (not just the trial) keeps sequential multi-subject
% captures correct: when the sessionLabel changes mid-session the router follows
% the capture instead of advancing a trial under the previously-selected subject.
%
% Host-only (needs the router UI); returns early if the router isn't present.

    if isempty(nexon), return; end
    try
        router = nexon.console.BASE.router;
    catch
        return;
    end
    if isempty(router), return; end

    ep = router.entryParams;

    % Subject field may be named 'subj' or 'subject'; the label always uses the
    % 'subj--' token, so parse with "subj" regardless of the entryParams name.
    subjField = "subj";
    if isfield(ep, "subject"), subjField = "subject"; end

    % Session coordinates = token after '--' for each level (e.g. "10191").
    coords = struct();
    coords.(subjField) = parseSessionLabel(sessionLabel, "subj");
    coords.date        = parseSessionLabel(sessionLabel, "date");
    coords.phase       = parseSessionLabel(sessionLabel, "phase");
    if isfield(ep, "site")
        coords.site = parseSessionLabel(sessionLabel, "site");
    end

    % Write session coordinates into entryParams (skip any the label lacks).
    % routerEntryChanged (fired below) recomputes the date/phase/site dropdown
    % Items+Values from these; only subj must be set on its uiField here because
    % the callback reads subj as a source and never writes it back.
    for f = string(fieldnames(coords))'
        if strlength(string(coords.(f))) == 0, continue; end
        router.entryParams.(f) = coords.(f);
    end

    % subj uiField: make the value selectable and set it (callback won't).
    setRouterField(router, subjField, coords.(subjField));

    % trial uiField: make the new trial selectable and set it; routerEntryChanged
    % preserves this value because we fire it with entryfield = "trial".
    setRouterField(router, "trial", string(trialNumber));

    routerEntryChanged(nexon, router, "trial");
end

function setRouterField(router, field, val)
% Set a router dropdown's Value, appending to Items first so App Designer does
% not reject a value that is not yet listed. No-op (guarded) when headless.
    val = string(val);
    if strlength(val) == 0, return; end
    try
        uf = router.Panel.(char(field)).uiField;
        if ~isvalid(uf), return; end
        if ~ismember(val, string(uf.Items))
            uf.Items = [string(uf.Items), val];
        end
        uf.Value = char(val);
    catch
    end
end
