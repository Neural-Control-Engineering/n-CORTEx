function DF = nexOp_eventAlignBySelection(nexon, DF, dtsIdx)
% Shift a trigger-relative DF time axis so t=0 lands on the event currently
% chosen in nexon.console.SLRT.signals.eventAlignmentSelection.
%
%   DF = nexOp_eventAlignBySelection(nexon, DF)          % current router trial
%   DF = nexOp_eventAlignBySelection(nexon, DF, dtsIdx)  % explicit DTS row
%
% Non-destructive, display-time alignment — the single-DF analogue of the
% offline nexOp_compileTF path, for a realtime nexFigure reloading a DF via
% reloadFromRouter. The stored ax_t is left trigger-relative (0 = world onset /
% insert); this only relabels the axis for the current view.
%
% Mechanics (mirrors nexOp_compileTF):
%   - The selected tag "<eventID>_<signalID>" splits to its eventID; that DTS
%     column holds the event's SAMPLE INDEX (fs_slrt units) from the buffered-
%     window start.
%   - nexOp_eventAlignDF relabels ax_t by (sample_event/Fs - preBuffLen) — the
%     event's trigger-relative time — moving 0 from the trigger to the event.
%   - isShift = 0: axis relabel only, no data circshift/resample.
%
% No-op (DF returned unchanged) when there is no SLRT signals bus, no/empty
% event selection, the DF has no t axis, or the event value is missing for this
% trial (e.g. the von Frey packet hasn't landed yet — the axis stays trigger-
% relative until it arrives, then re-aligns on the next refresh).

    if isempty(DF) || ~isfield(DF, 'ax') || ~isfield(DF.ax, 't'), return; end

    % SLRT signals bus (holds the event selection + Fs). Absent when no
    % slrtTimeCourse has been launched → nothing to align to.
    try
        signals = nexon.console.SLRT.signals;
    catch
        return;
    end
    if isempty(signals) || ~isprop(signals, 'eventAlignmentSelection'), return; end

    % Resolve the selected event tag → eventID (first "_"-split token).
    S_slrt = nex_returnSelectionMask(signals.eventAlignmentSelection);
    if ~isfield(S_slrt, 'events'), return; end
    evTag = string(S_slrt.events);
    if isempty(evTag) || strlength(evTag(1)) == 0, return; end
    alignColTags = split(evTag(1), "_");
    eventID = alignColTags(1);

    % Fs + preBuffLen. The sample_event index is measured against the SLRT
    % signal buffer, so signals.preBuffLen is the correct reference; a
    % BASE.UserData.preBuffLen override (matching nexOp_compileTF) takes
    % precedence if present. Must be non-empty — an empty t_preBuff makes
    % nexOp_eventAlignDF's guarded fallback misalign by a whole preBuffLen.
    fs_slrt   = signals.UserData.Fs;
    t_preBuff = 3.5;
    if isprop(signals, 'preBuffLen') && ~isempty(signals.preBuffLen)
        t_preBuff = signals.preBuffLen;
    end
    if isfield(nexon.console.BASE.UserData, "preBuffLen") && ...
            ~isempty(nexon.console.BASE.UserData.preBuffLen)
        t_preBuff = nexon.console.BASE.UserData.preBuffLen;
    end

    % Resolve the trial row (mirror dtsIO_readDF's empty-index resolution so the
    % event value comes from the same row as the DF).
    if nargin < 3 || isempty(dtsIdx)
        ridx = nex_getRouterIdx(nexon);
        if islogical(ridx), ridx = find(ridx); end
        if isempty(ridx), return; end
        dtsIdx = ridx(1);
    end

    % Read the event's per-trial sample index (scalar manifest column).
    sample_event = [];
    try
        v = dtsIO_readTFH5(nexon.console.BASE.DTS, eventID, dtsIdx, 'simple');
        if iscell(v), v = v{1}; end
        if ~isempty(v), sample_event = double(v(1)); end
    catch
        return;
    end
    if isempty(sample_event) || ~isfinite(sample_event), return; end

    % Relabel the axis (no data shift).
    DF = nexOp_eventAlignDF(DF, sample_event, fs_slrt, t_preBuff, 0);
end
