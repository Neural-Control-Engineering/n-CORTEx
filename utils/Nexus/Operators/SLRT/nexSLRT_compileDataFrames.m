function DF = nexSLRT_compileDataFrames(nexon, IDs_signals, eventTag, Fs, preBuffLen)
% Compile event-aligned signal dataframes for the current router trial.
%
%   DF = nexSLRT_compileDataFrames(nexon, IDs_signals, eventTag, Fs, preBuffLen)
%
% Reads the current router trial's data for each signal in IDs_signals,
% reads the event sample index encoded in eventTag, and aligns each signal
% to that event via nexOp_eventAlignDF.  Single-trial display — no averaging.
%
% Signals absent from the DTS are silently skipped.  nexPlot_slrt_timeCourse
% renders only the fields that are populated.
%
% eventTag format: "<eventID>_<signalID>", consistent with nexOp_compileTF.

    DF.df  = struct();
    DF.ax.t = struct();

    if isempty(eventTag) || isequal(string(eventTag), "")
        return;
    end

    % ── Resolve event column name from tag ───────────────────────────────
    % Match tag prefix against known event IDs (robust to underscores in names).
    DTSCols          = string(dtsIO_readDFIDs(nexon.console.BASE.DTS));
    IDs_events_all   = nex_getEventTypes(nexon);
    IDs_events_avail = IDs_events_all(ismember(IDs_events_all, DTSCols));

    eventID = "";
    for ei = 1:numel(IDs_events_avail)
        if startsWith(string(eventTag), IDs_events_avail(ei) + "_")
            eventID = IDs_events_avail(ei);
            break;
        end
    end
    if eventID == ""
        parts   = split(string(eventTag), "_");
        eventID = parts(1);
    end

    % ── Current router trial event sample index ───────────────────────────
    % dtsIO_readDF with empty index resolves the current router trial.
    sample_event = [];
    try
        DF_ev = dtsIO_readDF(nexon, char(eventID), []);
        if ~isempty(DF_ev) && isstruct(DF_ev) && isfield(DF_ev, 'df') && ~isempty(DF_ev.df)
            sample_event = DF_ev.df;
            if iscell(sample_event), sample_event = sample_event{1}; end
        end
    catch
    end

    % ── Per-signal: read → align → store ─────────────────────────────────
    for i = 1:numel(IDs_signals)
        sigID     = char(IDs_signals(i));
        fieldName = matlab.lang.makeValidName(sigID);
        try
            DF_sig = dtsIO_readDF(nexon, sigID, []);
            if isempty(DF_sig) || ~isstruct(DF_sig) || ...
                    ~isfield(DF_sig, 'df') || isempty(DF_sig.df)
                continue;
            end

            if ~isempty(sample_event) && isscalar(sample_event)
                DF_aligned = nexOp_eventAlignDF(DF_sig, sample_event, Fs, preBuffLen, 1);
            else
                DF_aligned = DF_sig;
            end

            DF.df.(fieldName)   = DF_aligned.df;
            DF.ax.t.(fieldName) = DF_aligned.ax.t;
        catch e
            fprintf('nexSLRT_compileDataFrames: skipping %s — %s\n', sigID, e.message);
        end
    end
end
